# ClipboardTyper – Implementation Notes

## Project structure

The project lives at the **repository root** (no nested `ClipboardTyper/ClipboardTyper`). Open the folder that contains `pubspec.yaml` as your workspace.

---

## What This App Does

ClipboardTyper lets you bind a **global shortcut** to “type” the current clipboard text into the **active window** as simulated keystrokes. It is aimed at **remote sessions** (RDP, VNC, etc.) where pasting is blocked or unreliable, so you can still enter long passwords, URLs, or other text.

- **Typing engine**: Windows `SendInput` with `KEYEVENTF_UNICODE`, so **all Unicode characters** (including `+`, `^`, `%`, `~`, `{}`, and any other “special” characters) are sent correctly without any escaping.
- **Global hotkey**: Configurable (default **Ctrl+Shift+V**); registered with the system so it works when the app is in the background or minimized to tray.
- **Run mode**: Normal Windows app that can be minimized to the **system tray** and optionally **start at Windows login** (no separate “service” install).

---

## Important Implementation Details

### 1. “Service” vs “App”

- A **real Windows Service** runs in **Session 0** and **cannot** send keystrokes to the user’s desktop or interact with the focused window. So “run as a service” in the sense of “type into the active window” is **not** possible with a true NT service.
- This app is implemented as a **normal desktop app** that:
  - Can be **minimized to the system tray** and run in the background.
  - Can be set to **start at login** (via `launch_at_startup`), which is the intended “service-like” behavior: start with Windows, stay in tray, react to the global hotkey.

So “install as service or app” is satisfied by: **install as app** + **optional “Start at login”** in settings.

### 2. Install Parameters and Uninstall

- **Install parameters** you asked for (shortcut key, clipboard access, service vs app) are handled **inside the app**:
  - **Shortcut**: Chosen in **Settings** (HotKey Recorder); stored in SharedPreferences and applied on next run.
  - **Clipboard access**: The app checks whether it can read the clipboard and shows status in Settings; on Windows desktop, clipboard access is normally allowed for focused/foreground apps.
  - **Service vs app**: No separate “service” binary; the only option is “Start ClipboardTyper at Windows login” in Settings (runs the same app at startup).
- **Registered and uninstallable as a Windows app**: Use **MSIX** packaging:
  - Add the `msix` dev dependency and `msix_config` in `pubspec.yaml` (already done).
  - Build: `flutter build windows` then `flutter pub run msix:create`.
  - The resulting `.msix` can be installed/uninstalled via **Settings → Apps** (or Add/Remove Programs), so the app is a normal Windows application.

### 3. Special Characters and Typing

- The PowerShell script you had escaped SendKeys special characters (`+^%~(){}`). This app **does not** use SendKeys; it uses **Win32 `SendInput`** with **`KEYEVENTF_UNICODE`**.
  - Each character is sent as its **Unicode code point** in the `KEYBDINPUT.wScan` field, so **all** characters (including `+`, `^`, `%`, `~`, `{}`, and any other Unicode symbol) are handled correctly without any escaping or mapping.
- A small **delay between keystrokes** (configurable in Settings) improves reliability in remote sessions.

### 4. Focus and UIPI

- Keystrokes go to the **currently focused** window. The user should focus the target (e.g. password field, notepad) before pressing the hotkey (or use the optional “initial delay” to give time to click into the field).
- **User Interface Privilege Isolation (UIPI)**: `SendInput` only affects processes at the same or lower integrity level. Running as a normal user, ClipboardTyper can type into other normal-user apps; it cannot type into elevated (admin) windows unless the app is also run elevated (generally not recommended).

### 5. Clipboard Access

- The app only **reads** the clipboard (plain text). It does not need “clipboard” capability in MSIX for writing; reading is typically allowed for desktop apps. The Settings screen shows whether clipboard read succeeded so users can see if something is wrong (e.g. policy or another app locking the clipboard).

### 6. Platform

- The typing implementation is **Windows-only** (Win32 `SendInput`). The Flutter project is set up with `--platforms=windows`. If you add other platforms later, you’d need a stub or no-op for the typist on non-Windows and guard usage with `Platform.isWindows`.

---

## Security

- **Clipboard length limit**: Typing is capped at a configurable maximum (default 100,000 characters; max 100,000). Prevents DoS from a huge clipboard and limits impact of accidental or malicious paste. Enforced in `lib/src/security.dart` and the typist.
- **Delay limits**: Initial delay and keystroke delay are clamped to sane ranges (e.g. initial 0–30s, typing 5–200 ms) so settings cannot be used to hang the app.
- **Optional double-press**: “Require double-press to type” in Settings forces the user to press the shortcut twice within 3 seconds before typing runs, reducing accidental or unintended typing (e.g. when another app steals focus).
- **No network**: The app does not use the network. MSIX is built without `internetClient` capability to reduce attack surface.
- **No secrets stored**: Settings (hotkey, delays, options) are stored in Windows user AppData via SharedPreferences. No passwords or clipboard history are persisted.
- **Error reporting**: Clipboard read and typing failures are reported via an optional callback (tray tooltip and SnackBar when Settings is open) instead of failing silently.
- **Single instance**: Running multiple copies will each register the same hotkey; behavior is per-process. For true single-instance, consider using a named mutex or `window_manager`’s single-instance APIs in the future.

---

## Build and Install

```bash
# Run in development
flutter run -d windows

# Build release
flutter build windows

# Create MSIX for install/uninstall as a Windows app
flutter pub run msix:create
```

The MSIX will be under `build/windows/runner/Release/`. Install it (double-click or `Add-AppxPackage`) and uninstall via **Settings → Apps** (or **Apps & features**).

---

## Summary

| Topic              | Implementation |
|--------------------|----------------|
| Special characters | `SendInput` + `KEYEVENTF_UNICODE`; no escaping. |
| Global hotkey      | Configurable in Settings; stored and reapplied on startup. |
| Clipboard access   | Read-only; status shown in Settings. |
| “Service” mode     | “Start at login” runs the same app in the background (tray). |
| Install/uninstall  | MSIX package; installs and uninstalls as a normal Windows app. |
| Security           | Length limit, delay limits, optional double-press, no network, no stored secrets. |
