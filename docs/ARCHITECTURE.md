# ClipboardTyper — Architecture

Code structure and main components.

---

## Project layout

```
ClipboardTyper/           # Repo root = Flutter project root
├── lib/
│   ├── main.dart              # App entry, tray, window, hotkey wiring
│   ├── settings_page.dart     # Settings UI
│   └── src/
│       ├── clipboard_typer_service.dart  # Hotkey registration, type-trigger logic
│       ├── settings.dart      # AppSettings model, load/save (SharedPreferences)
│       ├── security.dart      # Limits (max chars, delay bounds), clamp helpers
│       └── typist.dart        # Win32 SendInput typing (Windows-only)
├── windows/                   # Windows runner and native build
├── assets/
│   └── tray_icon.ico
├── test/
├── docs/                      # Markdown documentation
├── pubspec.yaml
├── README.md
└── IMPLEMENTATION_NOTES.md
```

---

## Main components

### `main.dart`

- **Responsibility**: Bootstrap, window lifecycle, tray, and wiring.
- **Behavior**:
  - Initializes `window_manager` and optionally hides the window on startup.
  - Sets up `launch_at_startup` (app name and path).
  - Builds `ClipboardTyperService` with an `onTypingError` callback (updates tray tooltip and app state for SnackBar).
  - Loads settings, registers the global hotkey, sets up tray icon and context menu.
  - Implements `WindowListener` (e.g. on close → hide to tray) and `TrayListener` (click → show window; menu → type / settings / exit).
- **Key state**: `_service`, `_lastTypingError` (for UI error display).

### `ClipboardTyperService` (`lib/src/clipboard_typer_service.dart`)

- **Responsibility**: Register the hotkey and run “type clipboard” when the shortcut is pressed (or from tray “Type now”).
- **Behavior**:
  - Holds current `AppSettings`; `registerHotkey()` registers the hotkey with `hotkey_manager`.
  - On hotkey: if “Require double-press” is on, first press arms (and starts a 3s window), second press within 3s runs typing; otherwise typing runs immediately.
  - Reads clipboard, enforces max length, applies initial delay, then calls `typeText()`.
  - Errors (empty clipboard, too long, read/type failure) reported via `onTypingError`.
- **Static** `typeClipboard()`: used by tray “Type now” and Settings “Type clipboard now”; takes initial delay, typing delay, and max chars as arguments.

### `typist.dart` (`lib/src/typist.dart`)

- **Responsibility**: Send a string as keystrokes to the active window.
- **Behavior**: Uses Win32 `SendInput` with `KEYEVENTF_UNICODE`; one INPUT per character (key down + key up). Enforces `maxChars` (default from `security.dart`). Delay between keys via `Sleep(delayMs)`.
- **Platform**: Windows-only (imports `win32`).

### `settings.dart` (`lib/src/settings.dart`)

- **Responsibility**: Define `AppSettings`, defaults, and persist to SharedPreferences.
- **Behavior**: `loadSettings()` reads prefs, deserializes hotkey (with validation/clamp via `security`), returns `AppSettings`. `saveSettings()` writes all fields. All numeric and length values are clamped to ranges defined in `security.dart`.

### `security.dart` (`lib/src/security.dart`)

- **Responsibility**: Central limits and helpers to prevent abuse and resource exhaustion.
- **Exports**: `maxClipboardChars`, `maxInitialDelaySec`, `maxTypingDelayMs`, `minTypingDelayMs`, `clampInt()`, `textRuneLength()`.
- **Used by**: settings (clamp on load and in `copyWith`), typist (max chars), service (length check before typing).

### `settings_page.dart`

- **Responsibility**: UI for all options and “Type clipboard now” button.
- **Behavior**: Uses `HotKeyRecorder` for the shortcut; sliders for delays and max chars; switches for “Require double-press” and “Start at login”. Shows clipboard access status. When `lastTypingError` is set, shows a SnackBar and clears it via `onClearTypingError`.

---

## Data flow

1. **Startup**: `main()` → load settings → create service with error callback → register hotkey → setup tray.
2. **User presses shortcut**: `hotkey_manager` fires → `_onHotKey` in service → (optional double-press handling) → read clipboard → enforce max length → delay → `typeText()`.
3. **User opens Settings**: `SettingsPage` gets `initialSettings` and `onSettingsChanged`; changes call `onSettingsChanged` (which updates service, re-registers hotkey, saves prefs, updates launch-at-startup).
4. **Tray “Type now”**: Calls `ClipboardTyperService.typeClipboard(...)` with current settings (e.g. from widget state).

---

## Dependencies (notable)

- **win32**: SendInput, Sleep, INPUT/KEYBDINPUT, KEYEVENTF_UNICODE.
- **hotkey_manager**: Global hotkey registration and handler.
- **tray_manager**: Tray icon, tooltip, context menu.
- **window_manager**: Window show/hide, close→minimize, options.
- **launch_at_startup**: Start at Windows login.
- **shared_preferences**: Persist settings (AppData).
