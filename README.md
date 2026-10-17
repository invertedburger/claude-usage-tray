# Claude Usage Tray

Two tiny Windows tray icons that show how much of your **Claude** plan limit is left — right on the taskbar, no hovering needed.

![icons](docs/preview.png)

| Icon | Limit |
|---|---|
| ◔ clock — colored slice shrinks as you use it | 5-hour session limit |
| 📅 calendar — colored fill drains downward | weekly limit |

- The number is the **% still available**; the colored slice / fill shows the same thing visually.
- Color: green ≥ 50 %, amber 20–49 %, red < 20 %. Grey `?` = data couldn't be loaded.
- Hover → reset time (e.g. "za 2 d 21 h (po 05:59)").
- Left click → refresh, double click → open claude.ai/settings/usage, right click → menu.
- Refreshes every 5 minutes. UI text is in Czech.

## Install

**Option A — one line.** Open PowerShell (Win + X → *Terminal*) and paste:

```powershell
irm https://raw.githubusercontent.com/invertedburger/claude-usage-tray/main/install.ps1 | iex
```

**Option B — double-click.** Download [**install.cmd**](https://github.com/invertedburger/claude-usage-tray/releases/latest/download/install.cmd) and run it. Windows SmartScreen may warn about a downloaded file — click *More info → Run anyway*.

Either way it installs to `%LOCALAPPDATA%\ClaudeUsageTray`, **starts automatically on login**, and launches right away. No admin rights needed. Run it again any time to update to the latest version.

Windows 11 hides new tray icons under the **^** arrow — drag them onto the taskbar once and they stay there.

### Requirements

- Windows 10/11 (uses the built-in Windows PowerShell — nothing else to install)
- Signed in to [Claude Code](https://claude.com/claude-code) (CLI or desktop app) with a Claude Pro/Max subscription — the app reads the OAuth token from `%USERPROFILE%\.claude\.credentials.json`.

## Uninstall

```powershell
irm https://raw.githubusercontent.com/invertedburger/claude-usage-tray/main/uninstall.ps1 | iex
```

## How it works

Every 5 minutes it calls `https://api.anthropic.com/api/oauth/usage` (the same data claude.ai shows under *Settings → Usage*) with your Claude Code OAuth token and redraws the icons with `System.Drawing`. The token never leaves your machine except in that request to Anthropic.

This endpoint is **undocumented** and may change without notice. The access token expires periodically; Claude Code / the desktop app refreshes it whenever you use them — until then the icons show `?`.

## License

MIT
