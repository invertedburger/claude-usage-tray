# Claude usage v system tray - dve ikony s % volneho limitu:
#   kolecko = 5h session, ctverec = tyden. Naplen ikony = kolik zbyva.
# Data: https://api.anthropic.com/api/oauth/usage s OAuth tokenem z ~/.claude/.credentials.json
# Bezi ve Windows PowerShell 5.1 i PowerShell 7. Soubor musi zustat UTF-8 s BOM (kvuli 5.1).

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type -Namespace Win32 -Name Native -MemberDefinition '[DllImport("user32.dll")] public static extern bool DestroyIcon(IntPtr h);'

$mutex = [System.Threading.Mutex]::new($false, 'Local\ClaudeUsageTray')
if (-not $mutex.WaitOne(0)) { exit }

$CredPath       = Join-Path $env:USERPROFILE '.claude\.credentials.json'
$RefreshMinutes = 5
$UsageUrl       = 'https://claude.ai/settings/usage'
$cs             = [System.Globalization.CultureInfo]::GetCultureInfo('cs-CZ')

function Get-Usage {
    $c = (Get-Content $CredPath -Raw -Encoding UTF8 | ConvertFrom-Json).claudeAiOauth
    Invoke-RestMethod -Uri 'https://api.anthropic.com/api/oauth/usage' -TimeoutSec 15 -Headers @{
        Authorization    = "Bearer $($c.accessToken)"
        'anthropic-beta' = 'oauth-2025-04-20'
    }
}

function ConvertTo-LocalTime($v) {
    if ($null -eq $v) { return $null }
    if ($v -is [datetime]) { return $v.ToLocalTime() }
    [datetimeoffset]::Parse($v).LocalDateTime
}

function Format-Reset($t) {
    if ($null -eq $t) { return '' }
    $span = $t - (Get-Date)
    $in = if ($span.TotalDays -ge 1) { '{0} d {1} h' -f [int][math]::Floor($span.TotalDays), $span.Hours }
          elseif ($span.TotalHours -ge 1) { '{0} h {1} min' -f [int][math]::Floor($span.TotalHours), $span.Minutes }
          else { '{0} min' -f [math]::Max(0, [int]$span.TotalMinutes) }
    $at = if ($t.Date -eq (Get-Date).Date) { $t.ToString('HH:mm', $cs) } else { $t.ToString('ddd HH:mm', $cs) }
    "za $in ($at)"
}

# Barva podle zbyvajiciho % (-1 = nezname)
function Get-Accent([int]$free) {
    if ($free -lt 0)      { [System.Drawing.Color]::FromArgb(140, 140, 150) }
    elseif ($free -ge 50) { [System.Drawing.Color]::FromArgb(52, 211, 153) }
    elseif ($free -ge 20) { [System.Drawing.Color]::FromArgb(251, 191, 36) }
    else                  { [System.Drawing.Color]::FromArgb(248, 113, 113) }
}

# "Nadrzka": tmave telo, zespodu barevna naplen do vysky $free %, cislo s obrysem.
# $shape: 'circle' (5h session) | 'square' (tyden)
function New-Icon([string]$text, [string]$shape, [int]$free) {
    $sz  = [System.Windows.Forms.SystemInformation]::SmallIconSize.Width
    $bmp = [System.Drawing.Bitmap]::new($sz, $sz)
    $g   = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $acc = Get-Accent $free

    $body = [System.Drawing.Drawing2D.GraphicsPath]::new()
    if ($shape -eq 'circle') {
        $body.AddEllipse(0, 0, $sz - 1, $sz - 1)
    } else {
        $r = [int]($sz / 5); $d = $r * 2; $w = $sz - 1
        $body.AddArc(0, 0, $d, $d, 180, 90); $body.AddArc($w - $d, 0, $d, $d, 270, 90)
        $body.AddArc($w - $d, $w - $d, $d, $d, 0, 90); $body.AddArc(0, $w - $d, $d, $d, 90, 90)
        $body.CloseFigure()
    }
    $bodyBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(30, 32, 40))
    $g.FillPath($bodyBrush, $body)

    if ($free -gt 0) {
        $h = $sz * $free / 100
        $dark = [System.Drawing.Color]::FromArgb([int]($acc.R * 0.55), [int]($acc.G * 0.55), [int]($acc.B * 0.55))
        $grad = [System.Drawing.Drawing2D.LinearGradientBrush]::new([System.Drawing.PointF]::new(0, $sz), [System.Drawing.PointF]::new(0, 0), $dark, $acc)
        $g.SetClip($body)
        $g.FillRectangle($grad, [single]0, [single]($sz - $h), [single]$sz, [single]$h)
        $g.ResetClip(); $grad.Dispose()
    }
    $rim = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(70, 255, 255, 255), 1)
    $g.DrawPath($rim, $body)

    $px = $sz * $(if ($text.Length -ge 3) { 0.42 } else { 0.6 })
    $sf = [System.Drawing.StringFormat]::new()
    $sf.Alignment = $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
    $tp = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $tp.AddString($text, [System.Drawing.FontFamily]::new('Segoe UI'), [int][System.Drawing.FontStyle]::Bold, [single]$px, [System.Drawing.RectangleF]::new(-1, 0, $sz + 2, $sz + 1), $sf)
    $outline = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(200, 0, 0, 0), [single]($sz / 8))
    $outline.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    $g.DrawPath($outline, $tp)
    $g.FillPath([System.Drawing.Brushes]::White, $tp)

    $hIcon = $bmp.GetHicon()
    $icon  = [System.Drawing.Icon]::FromHandle($hIcon).Clone()
    [void][Win32.Native]::DestroyIcon($hIcon)
    $g.Dispose(); $bmp.Dispose(); $body.Dispose(); $bodyBrush.Dispose(); $rim.Dispose(); $sf.Dispose(); $tp.Dispose(); $outline.Dispose()
    $icon
}

function Set-Tray($tray, [System.Drawing.Icon]$icon, [string]$text) {
    $old = $tray.Icon
    $tray.Icon = $icon
    if ($old) { $old.Dispose() }
    $tray.Text = if ($text.Length -gt 127) { $text.Substring(0, 127) } else { $text }
}

function Invoke-Refresh {
    try {
        $u = Get-Usage
        $sFree  = [math]::Max(0, 100 - [int][math]::Round($u.five_hour.utilization))
        $wFree  = [math]::Max(0, 100 - [int][math]::Round($u.seven_day.utilization))
        $sReset = ConvertTo-LocalTime $u.five_hour.resets_at
        $wReset = ConvertTo-LocalTime $u.seven_day.resets_at

        Set-Tray $traySession (New-Icon "$sFree" 'circle' $sFree) "Claude 5h limit: $sFree % volné`nReset $(Format-Reset $sReset)"
        Set-Tray $trayWeek (New-Icon "$wFree" 'square' $wFree) "Claude týdenní limit: $wFree % volné`nReset $(Format-Reset $wReset)"

        $miSession.Text = "5h limit: $sFree % volné, reset $(Format-Reset $sReset)"
        $miWeek.Text    = "Týden: $wFree % volné, reset $(Format-Reset $wReset)"
        $miUpdated.Text = 'Aktualizováno ' + (Get-Date).ToString('HH:mm')
    } catch {
        $msg = $_.Exception.Message
        $code = try { [int]$_.Exception.Response.StatusCode } catch { 0 }
        if ($code -eq 401) { $msg = 'Token vypršel – otevři Claude (Code/Desktop), obnoví se sám.' }
        Set-Tray $traySession (New-Icon '?' 'circle' -1) "Claude usage – chyba:`n$msg"
        Set-Tray $trayWeek (New-Icon '?' 'square' -1) "Claude usage – chyba:`n$msg"
        $miUpdated.Text = 'Chyba: ' + $msg
    }
}

# --- UI ---
$menu = [System.Windows.Forms.ContextMenuStrip]::new()
$miSession = $menu.Items.Add('5h limit: …');  $miSession.Enabled = $false
$miWeek    = $menu.Items.Add('Týden: …');     $miWeek.Enabled    = $false
$miUpdated = $menu.Items.Add('Načítám…');     $miUpdated.Enabled = $false
[void]$menu.Items.Add([System.Windows.Forms.ToolStripSeparator]::new())
$miRefresh = $menu.Items.Add('Obnovit');                  $miRefresh.add_Click({ Invoke-Refresh })
$miOpen    = $menu.Items.Add('Otevřít claude.ai usage');  $miOpen.add_Click({ Start-Process $UsageUrl })
[void]$menu.Items.Add([System.Windows.Forms.ToolStripSeparator]::new())
$miExit    = $menu.Items.Add('Ukončit')
$miExit.add_Click({ $traySession.Visible = $false; $trayWeek.Visible = $false; [System.Windows.Forms.Application]::Exit() })

# Poradi vytvoreni = poradi v trayi (tyden vlevo, 5h vpravo u hodin)
$trayWeek    = [System.Windows.Forms.NotifyIcon]::new()
$traySession = [System.Windows.Forms.NotifyIcon]::new()
foreach ($t in $trayWeek, $traySession) {
    $t.ContextMenuStrip = $menu
    $t.add_MouseClick({ param($s, $e) if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) { Invoke-Refresh } })
    $t.add_DoubleClick({ Start-Process $UsageUrl })
}
Set-Tray $trayWeek    (New-Icon '…' 'square' -1) 'Claude týdenní limit – načítám…'
Set-Tray $traySession (New-Icon '…' 'circle' -1) 'Claude 5h limit – načítám…'
$trayWeek.Visible = $true
$traySession.Visible = $true

$timer = [System.Windows.Forms.Timer]::new()
$timer.Interval = $RefreshMinutes * 60 * 1000
$timer.add_Tick({ Invoke-Refresh })
$timer.Start()

Invoke-Refresh
[System.Windows.Forms.Application]::Run()

$timer.Dispose(); $trayWeek.Dispose(); $traySession.Dispose(); $mutex.ReleaseMutex()