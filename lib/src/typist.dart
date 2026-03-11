import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:clipboard_typer/src/security.dart' as sec;

/// Sends text as keystrokes to the active window using Win32 SendInput
/// with KEYEVENTF_UNICODE. Handles all Unicode characters including
/// special characters (+, ^, %, ~, {}, etc.) without escaping.
///
/// Only works on Windows. For use in remote sessions where paste is blocked.
///
/// Throws [StateError] if [text] length exceeds [maxChars] (default [sec.maxClipboardChars]).
/// [delayMs] is clamped to at least [sec.minTypingDelayMs]; 0ms causes dropped characters.
/// [maxChars] is clamped to 1..[sec.maxClipboardChars].
void typeText(String text, {int delayMs = 15, int? maxChars}) {
  if (text.isEmpty) return;
  final effectiveDelay = delayMs < sec.minTypingDelayMs ? sec.minTypingDelayMs : delayMs;
  final limit = sec.clampInt(maxChars ?? sec.maxClipboardChars, 1, sec.maxClipboardChars);
  final runes = text.runes.toList();
  if (runes.length > limit) {
    throw StateError('Clipboard too long (${runes.length} chars). Max: $limit');
  }

  final kbd = calloc<INPUT>();
  try {
    kbd.ref.type = INPUT_KEYBOARD;
    kbd.ref.ki.wVk = 0;
    kbd.ref.ki.time = 0;
    kbd.ref.ki.dwExtraInfo = 0;

    for (int i = 0; i < runes.length; i++) {
      final codeUnit = runes[i];

      kbd.ref.ki.wScan = codeUnit;
      kbd.ref.ki.dwFlags = KEYEVENTF_UNICODE;
      SendInput(1, kbd, sizeOf<INPUT>());

      kbd.ref.ki.dwFlags = KEYEVENTF_UNICODE | KEYEVENTF_KEYUP;
      SendInput(1, kbd, sizeOf<INPUT>());

      if (i < runes.length - 1) {
        Sleep(effectiveDelay);
      }
    }
  } finally {
    free(kbd);
  }
}
