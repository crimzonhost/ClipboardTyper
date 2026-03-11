import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clipboard_typer/src/security.dart' as sec;

const _keyHotKey = 'hotkey';
const _keyInitialDelaySec = 'initial_delay_sec';
const _keyTypingDelayMs = 'typing_delay_ms';
const _keyStartAtLogin = 'start_at_login';
const _keyRequireConfirmation = 'require_confirmation';
const _keyMaxClipboardChars = 'max_clipboard_chars';

/// Default: Ctrl+Shift+V
HotKey get defaultHotKey => HotKey(
      key: PhysicalKeyboardKey.keyV,
      modifiers: [HotKeyModifier.control, HotKeyModifier.shift],
      scope: HotKeyScope.system,
    );

const int defaultInitialDelaySec = 2;
const int defaultTypingDelayMs = 15;

/// Default max characters to type from clipboard (security limit).
const int defaultMaxClipboardChars = 100000;

class AppSettings {
  AppSettings({
    required this.hotKey,
    this.initialDelaySec = defaultInitialDelaySec,
    this.typingDelayMs = defaultTypingDelayMs,
    this.startAtLogin = false,
    this.requireConfirmation = false,
    this.maxClipboardChars = defaultMaxClipboardChars,
  });

  final HotKey hotKey;
  final int initialDelaySec;
  final int typingDelayMs;
  final bool startAtLogin;
  final bool requireConfirmation;
  final int maxClipboardChars;

  AppSettings copyWith({
    HotKey? hotKey,
    int? initialDelaySec,
    int? typingDelayMs,
    bool? startAtLogin,
    bool? requireConfirmation,
    int? maxClipboardChars,
  }) {
    return AppSettings(
      hotKey: hotKey ?? this.hotKey,
      initialDelaySec: sec.clampInt(initialDelaySec ?? this.initialDelaySec, 0, sec.maxInitialDelaySec),
      typingDelayMs: sec.clampInt(typingDelayMs ?? this.typingDelayMs, sec.minTypingDelayMs, sec.maxTypingDelayMs),
      startAtLogin: startAtLogin ?? this.startAtLogin,
      requireConfirmation: requireConfirmation ?? this.requireConfirmation,
      maxClipboardChars: sec.clampInt(maxClipboardChars ?? this.maxClipboardChars, 1, sec.maxClipboardChars),
    );
  }
}

Future<AppSettings> loadSettings() async {
  final prefs = await SharedPreferences.getInstance();
  HotKey hotKey = defaultHotKey;
  try {
    final json = prefs.getString(_keyHotKey);
    if (json != null) {
      final map = jsonDecode(json);
      if (map is Map<String, dynamic> && map.containsKey('key')) {
        hotKey = HotKey.fromJson(map);
        hotKey = HotKey(
          identifier: hotKey.identifier,
          key: hotKey.key,
          modifiers: hotKey.modifiers,
          scope: HotKeyScope.system,
        );
      }
    }
  } catch (_) {}
  final rawInitial = prefs.getInt(_keyInitialDelaySec) ?? defaultInitialDelaySec;
  final rawTyping = prefs.getInt(_keyTypingDelayMs) ?? defaultTypingDelayMs;
  final rawMax = prefs.getInt(_keyMaxClipboardChars) ?? defaultMaxClipboardChars;
  return AppSettings(
    hotKey: hotKey,
    initialDelaySec: sec.clampInt(rawInitial, 0, sec.maxInitialDelaySec),
    typingDelayMs: sec.clampInt(rawTyping, sec.minTypingDelayMs, sec.maxTypingDelayMs),
    startAtLogin: prefs.getBool(_keyStartAtLogin) ?? false,
    requireConfirmation: prefs.getBool(_keyRequireConfirmation) ?? false,
    maxClipboardChars: sec.clampInt(rawMax, 1, sec.maxClipboardChars),
  );
}

Future<void> saveSettings(AppSettings s) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_keyHotKey, jsonEncode(s.hotKey.toJson()));
  await prefs.setInt(_keyInitialDelaySec, s.initialDelaySec);
  await prefs.setInt(_keyTypingDelayMs, s.typingDelayMs);
  await prefs.setBool(_keyStartAtLogin, s.startAtLogin);
  await prefs.setBool(_keyRequireConfirmation, s.requireConfirmation);
  await prefs.setInt(_keyMaxClipboardChars, s.maxClipboardChars);
}
