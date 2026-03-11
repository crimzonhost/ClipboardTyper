# ClipboardTyper — Build and release

How to build, package, install, and uninstall the app.

---

## Prerequisites

- **Flutter** SDK (stable channel recommended).
- **Windows** 10 or 11 (build host and target).
- **Visual Studio** or **Visual Studio Build Tools** with “Desktop development with C++” for the Windows runner.

---

## Development run

```bash
# From the project root (folder containing pubspec.yaml)
flutter run -d windows
```

The app starts; you can hot reload during development. The first run may take longer while the Windows runner is built.

---

## Release build (executable)

```bash
flutter build windows
```

Output:

- `build/windows/x64/runner/Release/` (or your configured architecture).
- Contains `clipboard_typer.exe` and the required DLLs/data. You can zip this folder for portable distribution.

---

## MSIX package (installable Windows app)

MSIX produces an installable package that appears in **Settings → Apps** and can be uninstalled cleanly.

### One-time setup

- `msix` is already a **dev dependency** in `pubspec.yaml`.
- `msix_config` in `pubspec.yaml` sets display name, identity, logo, and disables store/network capability.

### Create the package

```bash
# 1. Build the Windows release binary
flutter build windows

# 2. Create the MSIX package
flutter pub run msix:create
```

The MSIX file is generated under `build/windows/x64/runner/Release/` (or your build output directory), e.g. `clipboard_typer_1.0.0.0_x64_Release.msix`.

### Install

- **Double-click** the `.msix` file, or
- **PowerShell** (run as user):  
  `Add-AppxPackage -Path ".\clipboard_typer_1.0.0.0_x64_Release.msix"`

The app will appear in Start and in **Settings → Apps**.

### Uninstall

- **Settings → Apps** → find “ClipboardTyper” → Uninstall, or
- **PowerShell**:  
  `Get-AppxPackage -Name *clipboardtyper* | Remove-AppxPackage`

---

## Configuration in `pubspec.yaml`

Relevant section:

```yaml
msix_config:
  display_name: ClipboardTyper
  publisher_display_name: ClipboardTyper
  identity_name: com.clipboardtyper.clipboard_typer
  msix_version: 1.0.0.0
  logo_path: assets/tray_icon.ico
  store: false
```

- **No `capabilities`** (or no `internetClient`) — app does not request network.
- **Version**: Bump `msix_version` (and optionally `version` in `pubspec.yaml`) for each release.
- **Logo**: Uses `assets/tray_icon.ico`; keep that asset in sync if you change the app icon.

---

## Versioning

- **pubspec.yaml** `version: 1.0.0+1` — used by Flutter and the Windows runner (product version).
- **msix_config** `msix_version: 1.0.0.0` — used by the MSIX package. Keep both in sync when releasing (e.g. 1.0.0+1 and 1.0.0.0).

---

## Troubleshooting

- **“Windows desktop not supported”**: Run `flutter config --enable-windows-desktop` and ensure the Flutter Windows toolchain is installed.
- **MSIX create fails**: Ensure `flutter build windows` completed successfully and that the path to `logo_path` exists under the project.
- **App doesn’t start after install**: Check that the correct architecture (e.g. x64) matches your OS. Install the same architecture MSIX you built.
