# ClipboardTyper — Build and release

How to build, package, install, and uninstall the app.

---

## Installation & downloads (for users)

Pre-built Windows builds are attached to [GitHub Releases](https://github.com/crimzonhost/ClipboardTyper/releases) for each version.

### Option A: Portable (no install)

1. Download the **portable zip** from the latest release (e.g. `ClipboardTyper-1.0.0-windows-x64-portable.zip`).
2. Extract the zip to any folder you like (e.g. `C:\Tools\ClipboardTyper` or a USB drive). You do **not** need to put it in Program Files.
3. Run `clipboard_typer.exe` from that folder. The app will run from the tray; you can create a shortcut to the exe if you want (e.g. on the desktop or Start menu).
4. Settings (hotkey, delays, “Start at login”) are stored in your user AppData; they are reused even if you move the folder later.

**Where to place the exe:** Anywhere you have read/execute permission. Common choices: a folder under your user directory (e.g. `%USERPROFILE%\Tools\ClipboardTyper`), a shared tools drive, or a portable drive. Do not place it inside system directories (e.g. `C:\Windows` or `Program Files`) unless you understand the implications.

### Option B: Installer (MSIX)

1. Download the **MSIX installer** from the latest release (e.g. `clipboard_typer_1.0.0.0_x64_Release.msix`).
2. Double-click the `.msix` file (or run it via **Settings → Apps → Advanced options → App execution aliases** if you use that flow). Approve the install prompt.
3. The app is installed per-user and appears in **Settings → Apps** and in Start. Uninstall via **Settings → Apps** when you no longer need it.

---

## Prerequisites (for building)

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

# 2. Create the MSIX package (answer N when asked to install the test certificate)
echo N | dart run msix:create
```

The MSIX file is generated under `build/windows/x64/runner/Release/`, e.g. `clipboard_typer.msix` (or a versioned name depending on the msix package).

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
  identity_name: com.clipboardtyper.clipboard-typer
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

## Automated release builds (GitHub Actions)

On each **published GitHub Release**, a workflow builds the app and attaches two artifacts to that release:

1. **MSIX installer** — `clipboard_typer_<msix_version>_x64_Release.msix` (install via double-click).
2. **Portable zip** — `ClipboardTyper-<tag>-windows-x64-portable.zip` (e.g. `ClipboardTyper-v1.0.0-windows-x64-portable.zip`; extract and run `clipboard_typer.exe` from any folder).

To cut a release: create a tag (e.g. `v1.0.0`), push it, then create a new Release from that tag in the GitHub UI and publish it. The workflow runs on `release: types: [published]` and uploads the two assets. Ensure `version` and `msix_version` in `pubspec.yaml` match the release tag (e.g. tag `v1.0.0` → version `1.0.0`).

---

## Putting release files on GitHub (manual upload)

If you have already built the portable zip and MSIX locally and want to publish them for users without using the workflow:

1. **Commit and push** your code to GitHub.
2. Go to **https://github.com/crimzonhost/ClipboardTyper/releases**.
3. Click **“Draft a new release”**.
4. Choose a **tag** (e.g. `v1.0.0`). If the tag doesn’t exist yet, create it (e.g. “Create new tag: v1.0.0”).
5. Set the **release title** (e.g. `Release 1.0.0` or `v1.0.0`) and add any release notes.
6. Attach the two files:
   - **Portable zip:** `ClipboardTyper-1.0.0-windows-x64-portable.zip` (from the project root after you run the build and zip steps).
   - **MSIX installer:** `build/windows/x64/runner/Release/clipboard_typer.msix`.
7. Click **“Publish release”**.

Users can then download both files from the release page. For future releases you can either repeat this (after building and zipping again) or rely on the GitHub Actions workflow by publishing the release and letting the workflow build and attach the assets.

---

## Troubleshooting

- **“Windows desktop not supported”**: Run `flutter config --enable-windows-desktop` and ensure the Flutter Windows toolchain is installed.
- **MSIX create fails**: Ensure `flutter build windows` completed successfully and that the path to `logo_path` exists under the project.
- **App doesn’t start after install**: Check that the correct architecture (e.g. x64) matches your OS. Install the same architecture MSIX you built.
