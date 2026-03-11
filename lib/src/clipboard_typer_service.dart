import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:clipboard_typer/src/settings.dart';
import 'package:clipboard_typer/src/typist.dart';
import 'package:clipboard_typer/src/security.dart' as sec;

/// Callback when typing is skipped or fails. Message is user-facing.
typedef TypingErrorCallback = void Function(String message);

/// Registers the global hotkey and triggers paste-as-type when pressed.
/// Enforces [AppSettings.maxClipboardChars] and optional double-press confirmation.
class ClipboardTyperService {
  ClipboardTyperService(this._settings, {this.onTypingError});

  AppSettings _settings;
  bool _registered = false;

  /// Called when clipboard is empty, too long, or typing fails.
  final TypingErrorCallback? onTypingError;

  AppSettings get settings => _settings;

  bool get isRegistered => _registered;

  void updateSettings(AppSettings s) {
    _settings = s;
  }

  /// Pending type: first hotkey press when [requireConfirmation] is true.
  DateTime? _pendingConfirmUntil;
  Timer? _pendingTimer;

  Future<void> registerHotkey() async {
    await hotKeyManager.unregisterAll();
    await hotKeyManager.register(
      _settings.hotKey,
      keyDownHandler: _onHotKey,
    );
    _registered = true;
  }

  Future<void> unregisterHotkey() async {
    _pendingTimer?.cancel();
    _pendingTimer = null;
    _pendingConfirmUntil = null;
    await hotKeyManager.unregisterAll();
    _registered = false;
  }

  Future<void> _onHotKey(HotKey _) async {
    if (_settings.requireConfirmation) {
      final now = DateTime.now();
      if (_pendingConfirmUntil != null && now.isBefore(_pendingConfirmUntil!)) {
        _pendingTimer?.cancel();
        _pendingTimer = null;
        _pendingConfirmUntil = null;
        await _typeClipboardInternal(
          initialDelaySec: _settings.initialDelaySec,
          typingDelayMs: _settings.typingDelayMs,
        );
        return;
      }
      _pendingConfirmUntil = now.add(const Duration(seconds: 3));
      _pendingTimer?.cancel();
      _pendingTimer = Timer(const Duration(seconds: 3), () {
        _pendingConfirmUntil = null;
      });
      onTypingError?.call('Press shortcut again within 3s to type');
      return;
    }
    await _typeClipboardInternal(
      initialDelaySec: _settings.initialDelaySec,
      typingDelayMs: _settings.typingDelayMs,
    );
  }

  Future<void> _typeClipboardInternal({
    required int initialDelaySec,
    required int typingDelayMs,
    int? maxChars,
  }) async {
    String? text;
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      text = data?.text;
    } catch (e) {
      if (kDebugMode) debugPrint('ClipboardTyper: clipboard read failed: $e');
      onTypingError?.call('Could not read clipboard');
      return;
    }
    if (text == null || text.isEmpty) {
      onTypingError?.call('Clipboard is empty');
      return;
    }
    final limit = maxChars ?? _settings.maxClipboardChars;
    if (sec.textRuneLength(text) > limit) {
      onTypingError?.call('Clipboard too long (max $limit characters)');
      return;
    }
    if (initialDelaySec > 0) {
      await Future<void>.delayed(Duration(seconds: initialDelaySec));
    }
    try {
      typeText(text, delayMs: typingDelayMs, maxChars: limit);
    } catch (e) {
      if (kDebugMode) debugPrint('ClipboardTyper: type failed: $e');
      onTypingError?.call('Typing failed');
    }
  }

  /// Reads clipboard text and types it into the active window.
  /// Used from tray "Type now" and Settings button; uses provided limits.
  static Future<void> typeClipboard({
    int initialDelaySec = 0,
    int typingDelayMs = defaultTypingDelayMs,
    int maxChars = sec.maxClipboardChars,
  }) async {
    String? text;
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      text = data?.text;
    } catch (_) {
      return;
    }
    if (text == null || text.isEmpty) return;
    if (sec.textRuneLength(text) > maxChars) return;
    if (initialDelaySec > 0) {
      await Future<void>.delayed(Duration(seconds: initialDelaySec));
    }
    try {
      typeText(text, delayMs: typingDelayMs, maxChars: maxChars);
    } catch (_) {}
  }
}
