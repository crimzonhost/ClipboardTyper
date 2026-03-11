# ClipboardTyper

**Type your clipboard into the active window** using a global shortcut. Built for remote sessions (RDP, VNC, etc.) where paste is blocked or unreliable.

- **Global hotkey** (default **Ctrl+Shift+V**) — works when the app is minimized to the tray  
- **Unicode support** — special characters (`+`, `^`, `%`, `~`, `{}`, etc.) typed correctly  
- **System tray** — “Type clipboard now”, Settings, Exit  
- **Start at login** — optional background run when Windows starts  

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
| [Build & release](docs/BUILD_AND_RELEASE.md) | Building and packaging (MSIX, install/uninstall) |
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
