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

---

## Security review (summary)

A code review was performed with the following results.

### Strengths

- **Clipboard**: Read-only, length-capped (1–100k runes), no persistence of content.
- **Input validation**: Delays and max characters are clamped in `security.dart` and when loading/saving settings; hotkey JSON errors fall back to defaults.
- **No secrets**: Only preferences in AppData; no credentials or clipboard history stored.
- **No network**: App and MSIX do not use network capabilities.
- **Typing**: Uses Win32 `SendInput` with `KEYEVENTF_UNICODE` only; no shell or command execution; UIPI limits which windows can receive input.
- **Transparency**: Errors from the hotkey path are reported via callback (tray tooltip, SnackBar when Settings open). After the review fix, "Type now" (tray and Settings button) also reports errors via the same callback.

### Issues addressed

- **Silent failure on "Type now"**: The static `typeClipboard()` used by the tray and Settings "Type clipboard now" actions did not report errors (empty clipboard, too long, read/type failure). An optional `onTypingError` parameter was added and wired so the user always gets feedback, consistent with the hotkey path.

### Hardening (follow-up)

- **Defense in depth**: All delay and length parameters are clamped to security bounds inside the service and typist, even when coming from already-valid settings (guards against future callers or corrupted state).
- **Hotkey load**: Stored hotkey JSON is validated (must be `Map` with `key` present) before use; invalid or corrupted prefs fall back to default hotkey.
- **Error display**: Clipboard check failure in Settings shows a generic message (“Clipboard access denied or unavailable”) instead of exception text, to avoid leaking paths or internal details.

### Recommendations

- **Dependencies**: Periodically run `dart pub outdated` and consider `dart pub global activate dep_audit` then `dep_audit` for dependency hygiene. Rely on pub.dev and known dependencies.
- **Single instance**: Implementing single-instance enforcement would reduce confusion and avoid duplicate hotkey handlers.
- **SDK/Flutter**: Keep Dart and Flutter versions current for security fixes (e.g. pub/client path traversal fixes in newer SDK/Flutter).
