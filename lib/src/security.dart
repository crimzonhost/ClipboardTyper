/// Security and safety limits to prevent abuse and resource exhaustion.
///
/// - Caps clipboard length so a malicious or huge paste cannot lock the app.
/// - Clamps user-configurable delays to sane ranges.
library;

/// Maximum number of characters (runes) we will ever type from the clipboard.
/// Prevents DoS from a huge clipboard and limits accidental mass-typing.
const int maxClipboardChars = 100000;

/// Maximum initial delay (seconds) allowed in settings.
const int maxInitialDelaySec = 30;

/// Maximum delay between keystrokes (ms) allowed in settings.
const int maxTypingDelayMs = 200;

/// Minimum delay between keystrokes (ms).
const int minTypingDelayMs = 5;

/// Clamps [value] to [min]-[max].
int clampInt(int value, int min, int max) {
  if (value < min) return min;
  if (value > max) return max;
  return value;
}

/// Returns [text] length in runes (Unicode code points). Used for limit checks.
int textRuneLength(String text) => text.runes.length;
