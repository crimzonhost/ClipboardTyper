# ClipboardTyper — Settings reference

Every setting in the app and what it does.

---

## Shortcut (global)

- **What it is**: The key combination that triggers “type clipboard” from anywhere.
- **Default**: Ctrl+Shift+V.
- **How to change**: Click the hotkey area and press the new combination (e.g. Ctrl+Alt+T). The app saves it immediately.
- **Scope**: System-wide; works when the app is in the background or in the tray.

---

## Initial delay (seconds)

- **What it is**: Time in **seconds** to wait after you press the shortcut before typing starts.
- **Default**: 2.
- **Range**: 0–30.
- **Use**: Gives you a moment to ensure the correct window/field is focused. Set to 0 if you always focus first.

---

## Delay between keystrokes (ms)

- **What it is**: Pause in **milliseconds** between each character typed.
- **Default**: 15.
- **Range**: 5–200.
- **Use**: Slightly higher values (e.g. 20–30) can improve reliability over slow or remote connections.

---

## Require double-press to type

- **What it is**: When **on**, you must press the shortcut **twice within 3 seconds** before typing runs. The first press only “arms” the action; the second press within 3s actually types.
- **Default**: Off.
- **Use**: Reduces accidental typing when the wrong window is focused or the shortcut is hit by mistake.

---

## Max characters to type

- **What it is**: Maximum number of characters (Unicode code points) that will be typed from the clipboard. If the clipboard is longer, only the first part up to this limit is typed (or an error is shown, depending on UI).
- **Default**: 100,000.
- **Range**: 1,000–100,000 (slider).
- **Use**: Safety limit to avoid runaway typing and abuse. Lower it if you only need short strings (e.g. passwords).

---

## Start ClipboardTyper at Windows login

- **What it is**: When **on**, the app is registered to start when you log in to Windows. It starts minimized to the tray so the shortcut is available without opening the window.
- **Default**: Off.
- **Use**: Turn on if you want the shortcut available as soon as you log in (e.g. for remote work).

---

## Clipboard access (read-only status)

- **What it is**: A status line that shows whether the app can read the clipboard (“This app can read the clipboard” or a warning).
- **Use**: Diagnostic only. If you see a warning, another app or policy may be blocking clipboard access.

---

## Persistence

All settings (including the hotkey) are stored in Windows user AppData via Flutter’s SharedPreferences. They are applied on next launch. No clipboard content or passwords are stored.
