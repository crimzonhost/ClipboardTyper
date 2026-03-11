# ClipboardTyper — Security

Security model, limits, and recommendations.

---

## Design goals

- **No silent abuse**: Limits and optional confirmation reduce accidental or malicious use.
- **Minimal privilege**: No network, no elevated execution by design, no storage of secrets.
- **Transparency**: Errors (clipboard read fail, typing fail, “too long”) are reported to the user.

---

## Implemented measures

### 1. Clipboard length limit

- **What**: Typing is capped at a configurable maximum number of characters (runes). Default 100,000; user can set 1,000–100,000 in Settings.
- **Where**: `lib/src/security.dart` defines the cap; `typist.dart` enforces it before typing; `clipboard_typer_service.dart` checks length before calling the typist.
- **Why**: Prevents DoS from a huge clipboard and limits impact of pasting into the wrong window.

### 2. Delay limits

- **What**: Initial delay (seconds) and keystroke delay (ms) are clamped to fixed ranges (e.g. 0–30 s and 5–200 ms).
- **Where**: `security.dart` constants; `settings.dart` clamps on load and in `copyWith`.
- **Why**: Prevents settings from being used to hang the app (e.g. “type one key every 10 minutes”).

### 3. Optional double-press

- **What**: When “Require double-press to type” is on, the user must press the shortcut **twice within 3 seconds** before typing runs.
- **Where**: `ClipboardTyperService._onHotKey`; pending state and timer cleared on unregister.
- **Why**: Reduces accidental typing when the wrong window is focused or the shortcut is hit by mistake.

### 4. No network

- **What**: The app does not open network connections. MSIX package is built **without** the `internetClient` capability.
- **Where**: `pubspec.yaml` `msix_config` has no `capabilities` (or explicit empty).
- **Why**: Shrinks attack surface and makes it clear the app is local-only.

### 5. No stored secrets

- **What**: Only preferences are persisted (hotkey, delays, “start at login”, “require double-press”, “max characters”). Stored in Windows user AppData via SharedPreferences.
- **Where**: `lib/src/settings.dart`; no code writes clipboard content or passwords to disk.
- **Why**: Even if prefs were read by another process, they would not reveal passwords or clipboard history.

### 6. Error reporting

- **What**: Clipboard read failure, “clipboard too long”, and typing failure are reported via an optional callback. The app shows them in the tray tooltip and, when the Settings window is open, in a SnackBar.
- **Where**: `ClipboardTyperService` `onTypingError`; `main.dart` passes a callback that updates state and tray tooltip.
- **Why**: Failures are visible instead of silent, so the user can correct focus or content.

---

## Windows-specific considerations

- **UIPI (User Interface Privilege Isolation)**: `SendInput` only affects processes at the same or lower integrity level. Running as a normal user, ClipboardTyper can type only into other normal-user windows, not into elevated (admin) apps, unless the app is itself run elevated (not recommended).
- **Focus**: Keystrokes go to the **focused** window. The user is responsible for focusing the correct window; the initial delay is there to allow that.
- **Clipboard**: The app only **reads** plain text from the clipboard. It does not write to the clipboard or monitor it continuously.

---

## What the app does *not* do

- Does not send data over the network.
- Does not store clipboard content or passwords.
- Does not run as a Windows Service (runs as a normal user app; “Start at login” just launches the same app at logon).
- Does not require admin rights for normal use or install (when installed per-user via MSIX).

---

## Recommendations for operators

- Use **“Require double-press to type”** in shared or locked-down environments to reduce accidental triggers.
- Lower **“Max characters to type”** if you only need short strings (e.g. passwords).
- Install via MSIX when possible so the app is a normal Windows app and can be uninstalled via Settings → Apps.
- Do not run the app elevated unless you have a specific need (and understand UIPI implications).

---

## Single instance (future)

Currently, running multiple copies of the app will each register the same hotkey; behavior is per-process and may be confusing. A future improvement is to enforce a single instance (e.g. named mutex or `window_manager` single-instance API) so only one process owns the hotkey.
