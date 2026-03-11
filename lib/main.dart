import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:clipboard_typer/src/settings.dart';
import 'package:clipboard_typer/src/clipboard_typer_service.dart';
import 'package:clipboard_typer/settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await hotKeyManager.unregisterAll();

  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      size: Size(520, 520),
      minimumSize: Size(440, 420),
      title: 'ClipboardTyper',
      skipTaskbar: false,
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.setTitleBarStyle(
        TitleBarStyle.normal,
        windowButtonVisibility: true,
      );
      await windowManager.hide();
    });

    launchAtStartup.setup(
      appName: 'ClipboardTyper',
      appPath: Platform.resolvedExecutable,
    );
  }

  runApp(const ClipboardTyperApp());
}

class ClipboardTyperApp extends StatefulWidget {
  const ClipboardTyperApp({super.key});

  @override
  State<ClipboardTyperApp> createState() => _ClipboardTyperAppState();
}

class _ClipboardTyperAppState extends State<ClipboardTyperApp>
    with WindowListener, TrayListener {
  late final ClipboardTyperService _service;
  String? _lastTypingError;

  AppSettings get _settings => _service.settings;

  void _onTypingError(String message) {
    if (!mounted) return;
    setState(() => _lastTypingError = message);
    if (Platform.isWindows) {
      trayManager.setToolTip('ClipboardTyper: $message');
    }
  }

  @override
  void initState() {
    super.initState();
    _service = ClipboardTyperService(
      AppSettings(
        hotKey: defaultHotKey,
        initialDelaySec: defaultInitialDelaySec,
        typingDelayMs: defaultTypingDelayMs,
        startAtLogin: false,
      ),
      onTypingError: _onTypingError,
    );
    windowManager.addListener(this);
    trayManager.addListener(this);
    _init();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    super.dispose();
  }

  Future<void> _init() async {
    final settings = await loadSettings();
    _service.updateSettings(settings);
    if (Platform.isWindows) {
      await _service.registerHotkey();
      await _setupTray();
      if (settings.startAtLogin) {
        try {
          await launchAtStartup.enable();
        } catch (_) {}
      }
    }
    setState(() {});
  }

  Future<void> _setupTray() async {
    await trayManager.setIcon(
      Platform.isWindows ? 'assets/tray_icon.ico' : 'assets/tray_icon.png',
    );
    await trayManager.setToolTip(
      'ClipboardTyper — ${_settings.hotKey.debugName} to type clipboard',
    );
    final menu = Menu(
      items: [
        MenuItem(
          key: 'type',
          label: 'Type clipboard now',
        ),
        MenuItem(key: 'settings', label: 'Settings'),
        MenuItem.separator(),
        MenuItem(key: 'exit', label: 'Exit'),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  @override
  void onWindowClose() async {
    final show = await windowManager.isVisible();
    if (show) {
      await windowManager.hide();
    } else {
      await windowManager.destroy();
    }
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
    windowManager.focus();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'type':
        ClipboardTyperService.typeClipboard(
          initialDelaySec: 0,
          typingDelayMs: _settings.typingDelayMs,
          maxChars: _settings.maxClipboardChars,
          onTypingError: _onTypingError,
        );
        break;
      case 'settings':
        windowManager.show();
        windowManager.focus();
        break;
      case 'exit':
        windowManager.destroy();
        break;
    }
  }

  void _onSettingsChanged(AppSettings s) {
    _service.updateSettings(s);
    _service.registerHotkey();
    saveSettings(s);
    if (Platform.isWindows && s.startAtLogin) {
      launchAtStartup.enable();
    } else {
      launchAtStartup.disable();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClipboardTyper',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: SettingsPage(
        initialSettings: _settings,
        onSettingsChanged: _onSettingsChanged,
        lastTypingError: _lastTypingError,
        onClearTypingError: () => setState(() => _lastTypingError = null),
        onTypeNow: () => ClipboardTyperService.typeClipboard(
          initialDelaySec: 0,
          typingDelayMs: _settings.typingDelayMs,
          maxChars: _settings.maxClipboardChars,
          onTypingError: _onTypingError,
        ),
      ),
    );
  }
}
