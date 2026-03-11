# ClipboardTyper

**Type your clipboard into the active window** using a global shortcut. Built for remote sessions (RDP, VNC, etc.) where paste is blocked or unreliable.

- **Global hotkey** (default **Ctrl+Shift+V**) — works when the app is minimized to the tray  
- **Unicode support** — special characters (`+`, `^`, `%`, `~`, `{}`, etc.) typed correctly  
- **System tray** — “Type clipboard now”, Settings, Exit  
- **Start at login** — optional background run when Windows starts  

---

## Download & install (Windows)

Pre-built Windows builds are on **GitHub Releases**. Choose one of the two options below.

### Option 1: Portable (no install)

1. Go to **[Releases](https://github.com/crimzonhost/ClipboardTyper/releases)** and open the latest release.
2. Download **`ClipboardTyper-1.0.0-windows-x64-portable.zip`** (or the current version’s portable zip).
3. Extract the zip to a folder (e.g. `C:\Tools\ClipboardTyper` or a USB drive). You can put it anywhere you have read/execute permission — no need for Program Files.
4. Run **`clipboard_typer.exe`** from that folder. The app runs in the system tray.
5. (Optional) Create a shortcut to `clipboard_typer.exe` on your desktop or Start menu.

Settings (hotkey, delays, “Start at login”) are stored in your user AppData and are kept if you move or replace the folder.

### Option 2: Installer (MSIX)

1. Go to **[Releases](https://github.com/crimzonhost/ClipboardTyper/releases)** and open the latest release.
2. Download the **MSIX** file (e.g. **`clipboard_typer.msix`**).
3. Double-click the `.msix` file and approve the install prompt.
4. The app is installed for your user and appears in **Settings → Apps** and in Start.
5. To uninstall: **Settings → Apps** → find “ClipboardTyper” → Uninstall.

**If Windows blocks the MSIX** (“certificate not trusted”), it’s signed with a test certificate. Use the **EXE installer** or **portable zip** instead, or see [Code signing](docs/SIGNING.md) to build a signed MSIX.

### Option 3: EXE installer (recommended if MSIX is blocked)

1. Go to **[Releases](https://github.com/crimzonhost/ClipboardTyper/releases)** and open the latest release.
2. Download **Setup ClipboardTyper x.x.x.exe** (or the current EXE installer).
3. Run the setup.exe and follow the wizard. No Store or certificate prompt.
4. Uninstall via **Settings → Apps** or **Add or remove programs**.

The EXE installer is built with Inno Setup. If the publisher has signed it with a code signing certificate, Windows will show the publisher and reduce warnings.

**Direct link:** [https://github.com/crimzonhost/ClipboardTyper/releases](https://github.com/crimzonhost/ClipboardTyper/releases)

**If the releases page is empty:** A maintainer needs to create the first release and attach the files. Set a GitHub Personal Access Token (repo scope), then run the script from the repo root:

```powershell
$env:GH_TOKEN = "ghp_your_token_here"   # Create at https://github.com/settings/tokens
.\scripts\create-release.ps1
```

No GitHub CLI required. See `scripts/create-release.ps1` for details.

---

## Quick start

```bash
# Open this folder in your IDE (project is at repo root)
cd path/to/ClipboardTyper

# Run
flutter run -d windows
```

1. Copy some text, focus the target window (e.g. password field), then press **Ctrl+Shift+V**.  
2. After the short initial delay, the clipboard is typed as keystrokes.  
3. Right-click the tray icon for “Type clipboard now” or “Settings”.

---

## Documentation

| Document | Description |
|----------|-------------|
| [User guide](docs/USER_GUIDE.md) | How to use the app, tray, and shortcut |
| [Settings](docs/SETTINGS.md) | All options (hotkey, delays, security, startup) |
| [Architecture](docs/ARCHITECTURE.md) | Code structure and main components |
| [Security](docs/SECURITY.md) | Security model, limits, and recommendations |
| [Build & release](docs/BUILD_AND_RELEASE.md) | Building and packaging (MSIX, EXE installer, install/uninstall) |
| [Code signing](docs/SIGNING.md) | Signing MSIX and EXE so Windows doesn't block install |
| [Implementation notes](IMPLEMENTATION_NOTES.md) | Design decisions, Windows behavior, summary table |
| [Changelog](CHANGELOG.md) | Version history |

---

## Requirements

- **Windows** 10 or 11  
- **Flutter** SDK (for building from source)  
- No admin rights required for normal use  

---

## Security at a glance

- **Clipboard length limit** — configurable cap (default 100k characters)  
- **Optional double-press** — require shortcut twice within 3s to type  
- **No network** — app does not use the internet  
- **No stored secrets** — only preferences in AppData  

See [docs/SECURITY.md](docs/SECURITY.md) for full details.

---

## License

See [LICENSE](LICENSE) if present; otherwise use as desired.
