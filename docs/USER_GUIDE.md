# ClipboardTyper — User guide

How to use ClipboardTyper day to day.

---

## What it does

ClipboardTyper **types the current clipboard text** into **whatever window is focused**, as if you had typed it by hand. It uses a **global shortcut** (default **Ctrl+Shift+V**), so it works even when the app is minimized to the system tray.

Typical use: copy a password or URL, click into the remote session’s password field or address bar, then press the shortcut. After a short delay, the text is “typed” character by character.

---

## First run

1. Start the app (`flutter run -d windows` or run the built executable).
2. The window may start hidden; click the **tray icon** (system tray near the clock) to open Settings.
3. Optionally change the **shortcut** in Settings (press the key combo you want).
4. Copy some text, focus Notepad or any text field, and press **Ctrl+Shift+V** (or your shortcut).

---

## Using the shortcut

1. **Copy** the text you want to type (e.g. password, URL).
2. **Focus** the target window and, if needed, the exact field (click in the password box, etc.).
3. Press the **global shortcut** (default **Ctrl+Shift+V**).
4. Wait for the **initial delay** (default 2 seconds) — you can use this time to ensure focus is correct.
5. The app then **types** the clipboard content with a small delay between keystrokes.

If **“Require double-press to type”** is enabled in Settings, you must press the shortcut **twice within 3 seconds**; the first press only arms the action.

---

## System tray

- **Left-click** the tray icon → opens the **Settings** window.
- **Right-click** → context menu:
  - **Type clipboard now** — types immediately (no initial delay).
  - **Settings** — open Settings.
  - **Exit** — quit the app.

Hovering the tray icon shows a tooltip with the current shortcut (e.g. “ClipboardTyper — Control + Shift + V to type clipboard”).

---

## Settings window

Open from the tray (left-click or menu → Settings). All options are described in [SETTINGS.md](SETTINGS.md). Main ones:

- **Shortcut** — global hotkey to trigger typing.
- **Initial delay** — seconds to wait before typing starts (time to fix focus).
- **Delay between keystrokes** — milliseconds between characters (helps in remote sessions).
- **Require double-press to type** — reduces accidental typing.
- **Start at login** — run ClipboardTyper when Windows starts (minimized to tray).

Closing the Settings window **minimizes to tray**; the app keeps running and the shortcut stays active.

---

## Tips

- **Remote sessions**: Increase “Delay between keystrokes” slightly if characters are dropped.
- **Long text**: If the clipboard is very long, the app will only type up to the “Max characters to type” limit (see Settings).
- **Errors**: If typing doesn’t happen, check that the target window is focused and that the clipboard contains plain text. Error messages appear in the tray tooltip and in a SnackBar when Settings is open.
