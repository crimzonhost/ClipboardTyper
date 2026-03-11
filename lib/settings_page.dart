import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:clipboard_typer/src/settings.dart';
import 'package:clipboard_typer/src/security.dart' as sec;

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.initialSettings,
    required this.onSettingsChanged,
    required this.onTypeNow,
    this.lastTypingError,
    this.onClearTypingError,
  });

  final AppSettings initialSettings;
  final ValueChanged<AppSettings> onSettingsChanged;
  final VoidCallback onTypeNow;
  final String? lastTypingError;
  final VoidCallback? onClearTypingError;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late AppSettings _settings;
  bool _clipboardOk = false;
  String? _clipboardError;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
    _checkClipboard();
  }

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lastTypingError != null && widget.lastTypingError != oldWidget.lastTypingError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.lastTypingError!), duration: const Duration(seconds: 4)),
        );
        widget.onClearTypingError?.call();
      });
    }
  }

  Future<void> _checkClipboard() async {
    if (!Platform.isWindows) return;
    try {
      await Clipboard.getData(Clipboard.kTextPlain);
      if (mounted) setState(() { _clipboardOk = true; _clipboardError = null; });
    } catch (e) {
      if (mounted) setState(() { _clipboardOk = false; _clipboardError = e.toString(); });
    }
  }

  void _apply() {
    widget.onSettingsChanged(_settings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ClipboardTyper'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Type clipboard into the active window (e.g. for remote sessions where paste is blocked).',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 24),
            // Hotkey
            const Text('Shortcut (global)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            HotKeyRecorder(
              initalHotKey: _settings.hotKey,
              onHotKeyRecorded: (h) {
                setState(() {
                  _settings = _settings.copyWith(
                    hotKey: HotKey(
                      identifier: _settings.hotKey.identifier,
                      key: h.key,
                      modifiers: h.modifiers,
                      scope: HotKeyScope.system,
                    ),
                  );
                  _apply();
                });
              },
            ),
            const SizedBox(height: 8),
            Text(
              _settings.hotKey.debugName,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            // Initial delay
            const Text('Initial delay (seconds)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Slider(
              value: _settings.initialDelaySec.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              label: '${_settings.initialDelaySec}s',
              onChanged: (v) {
                setState(() {
                  _settings = _settings.copyWith(initialDelaySec: v.toInt());
                  _apply();
                });
              },
            ),
            Text('${_settings.initialDelaySec} seconds before typing starts', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            // Typing delay
            const Text('Delay between keystrokes (ms)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Slider(
              value: _settings.typingDelayMs.toDouble(),
              min: 5,
              max: 100,
              divisions: 19,
              label: '${_settings.typingDelayMs}ms',
              onChanged: (v) {
                setState(() {
                  _settings = _settings.copyWith(typingDelayMs: v.toInt());
                  _apply();
                });
              },
            ),
            Text('${_settings.typingDelayMs} ms', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 20),
            // Require confirmation (double-press)
            SwitchListTile(
              title: const Text('Require double-press to type'),
              subtitle: const Text('Press shortcut twice within 3s to reduce accidental typing'),
              value: _settings.requireConfirmation,
              onChanged: (v) {
                setState(() {
                  _settings = _settings.copyWith(requireConfirmation: v);
                  _apply();
                });
              },
            ),
            const SizedBox(height: 8),
            // Max clipboard length
            const Text('Max characters to type', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Slider(
              value: _settings.maxClipboardChars.clamp(1000, sec.maxClipboardChars).toDouble(),
              min: 1000,
              max: sec.maxClipboardChars.toDouble(),
              divisions: (sec.maxClipboardChars ~/ 1000).clamp(1, 100),
              label: '${_settings.maxClipboardChars}',
              onChanged: (v) {
                setState(() {
                  _settings = _settings.copyWith(maxClipboardChars: v.toInt());
                  _apply();
                });
              },
            ),
            Text('${_settings.maxClipboardChars} characters max (security limit)', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 20),
            // Start at login
            if (Platform.isWindows) ...[
              SwitchListTile(
                title: const Text('Start ClipboardTyper at Windows login'),
                subtitle: const Text('Runs in the background (system tray)'),
                value: _settings.startAtLogin,
                onChanged: (v) {
                  setState(() {
                    _settings = _settings.copyWith(startAtLogin: v);
                    _apply();
                  });
                },
              ),
              const SizedBox(height: 16),
            ],
            // Clipboard access
            const Text('Clipboard access', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  _clipboardOk ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: _clipboardOk ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _clipboardOk
                        ? 'This app can read the clipboard.'
                        : (_clipboardError ?? 'Clipboard access could not be verified.'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: widget.onTypeNow,
              icon: const Icon(Icons.keyboard),
              label: const Text('Type clipboard now'),
            ),
            const SizedBox(height: 8),
            Text(
              'Minimize to tray; use the shortcut or tray menu to type clipboard into the focused window.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
