// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'package:macos_liquid_glass_ui/src/buttons/button_interaction.dart';

import 'package:flutter/services.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';
import 'package:macos_liquid_glass_ui/src/library.dart';

const _methodChannel = MethodChannel('dev.groovinchip.macos_ui');
const _eventChannel = EventChannel('dev.groovinchip.macos_ui/color_panel');

/// Describes the possible modes for an `NSColorPanel`.
///
/// Source documentation: https://developer.apple.com/documentation/appkit/nscolorpanel/mode
enum ColorPickerMode {
  /// No color panel mode.
  none,

  /// The grayscale-alpha color mode.
  gray,

  /// The red-green-blue color mode.
  RBG,

  /// The cyan-magenta-yellow-black color mode.
  CMYK,

  /// The hue-saturation-brightness color mode.
  HSB,

  /// The custom palette color mode.
  customPalette,

  /// The custom color list mode.
  colorList,

  /// The color wheel mode.
  wheel,

  /// The crayon picker mode.
  crayon,
}

/// {@template onColorSelected}
/// The action to perform when a color is selected from the color well.
/// {@endtemplate}
typedef OnColorSelected = void Function(Color color);

/// {@template macosColorWell}
/// A control that displays a color value and lets the user change that color
/// value.
///
/// When a `MacosColorWell` is clicked, it opens the native macOS color panel,
/// which is an `NSColorPanel` from the Swift Cocoa library.
///
/// Use a [MacosColorWell] when you want the user to be able to select a color.
/// {@endtemplate}
class MacosColorWell extends StatefulWidget {
  /// {@macro macosColorWell}
  const MacosColorWell({
    super.key,
    required this.onColorSelected,
    this.defaultMode = ColorPickerMode.wheel,
    this.color,
    this.enabled = true,
    this.semanticLabel = 'Choose colour',
  });

  /// Controlled colour. Null retains the last selection internally.
  final Color? color;

  /// Whether this well can open the application-wide native panel.
  final bool enabled;

  /// Accessible name for this well.
  final String semanticLabel;

  /// {@macro onColorSelected}
  final OnColorSelected onColorSelected;

  /// The default [ColorPickerMode] to open the `NSColorPanel` with.
  ///
  /// Defaults to [ColorPickerMode.wheel].
  final ColorPickerMode defaultMode;

  @override
  State<MacosColorWell> createState() => _MacosColorWellState();
}

// NSColorPanel is application-wide. One owner receives changes; no per-window
// panel contract is implied. Serialise listen/open/cancel to avoid stale owners.
class _ColorPanelSession {
  static Object? owner;
  static Future<void>? pending;
  static Future<void> run(Future<void> Function() operation) {
    final task = (pending ?? Future<void>.value()).then((_) => operation());
    pending = task;
    task.then<void>(
      (_) {
        if (identical(pending, task)) pending = null;
      },
      onError: (Object error, StackTrace stack) {
        if (identical(pending, task)) pending = null;
      },
    );
    return task;
  }

  static Future<void> close(Object token) => run(() async {
    if (owner != token) return;
    owner = null;
    ServicesBinding.instance.defaultBinaryMessenger.setMessageHandler(
      _eventChannel.name,
      null,
    );
    try {
      await _methodChannel.invokeMethod<void>('close_color_panel');
    } on PlatformException catch (_) {
    } on MissingPluginException catch (_) {}
    try {
      await MethodChannel(_eventChannel.name).invokeMethod<void>('cancel');
    } on PlatformException catch (_) {
    } on MissingPluginException catch (_) {}
  });
}

class _MacosColorWellState extends State<MacosColorWell> {
  final _focus = FocusNode();
  Color? _selectedColor;
  Object? _session;
  bool _opening = false;

  bool get _visible =>
      mounted &&
      widget.enabled &&
      (Focus.maybeOf(context)?.descendantsAreFocusable ?? true) &&
      TickerMode.valuesOf(context).enabled;

  void _close() {
    final token = _session;
    _session = null;
    if (token != null) unawaited(_ColorPanelSession.close(token));
  }

  @override
  void didUpdateWidget(MacosColorWell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.color != oldWidget.color) _selectedColor = widget.color;
    if (!widget.enabled) _close();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_visible) _close();
  }

  Future<void> _open() async {
    if (!_visible || _opening) return;
    _opening = true;
    final token = Object();
    _session = token;
    await _ColorPanelSession.run(() async {
      if (!mounted || _session != token || !_visible) return;
      _ColorPanelSession.owner = token;
      ServicesBinding.instance.defaultBinaryMessenger.setMessageHandler(
        _eventChannel.name,
        (message) async {
          if (!mounted ||
              _session != token ||
              _ColorPanelSession.owner != token ||
              !_visible) {
            return null;
          }
          if (message == null) {
            _close();
            return null;
          }
          dynamic event;
          try {
            event = const StandardMethodCodec().decodeEnvelope(message);
          } on PlatformException {
            _close();
            return null;
          } catch (_) {
            return null;
          }
          final value = event is String ? int.tryParse(event) : null;
          if (value == null || value < 0 || value > 0xFFFFFFFF) return null;
          final color = Color(value);
          if (color == _selectedColor || color == widget.color) return null;
          setState(() => _selectedColor = color);
          widget.onColorSelected(color);
          return null;
        },
      );
      try {
        await MethodChannel(_eventChannel.name).invokeMethod<void>('listen');
        if (!mounted || _session != token || !_visible) return;
        await _methodChannel.invokeMethod<void>('color_panel', {
          'mode': '${widget.defaultMode}',
          'color': (widget.color ?? _selectedColor)?.toARGB32(),
        });
      } on MissingPluginException {
        _close();
      } on PlatformException {
        _close();
      }
    });
    _opening = false;
  }

  @override
  void dispose() {
    _close();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chrome = MacosChromeData.of(context);
    return ButtonInteraction(
      label: widget.semanticLabel,
      focusNode: _focus,
      onPressed: widget.enabled ? _open : null,
      onHeldChanged: (_) {},
      builder: (context, states) => ButtonFocusRing(
        states: states,
        child: Container(
          height: 28,
          width: 48,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: chrome.backgroundFor(states),
            border: Border.all(color: chrome.separator),
          ),
          child: Opacity(
            opacity: widget.enabled ? 1 : 0.5,
            child: ColoredBox(
              color:
                  widget.color ?? _selectedColor ?? MacosColors.systemBlueColor,
            ),
          ),
        ),
      ),
    );
  }
}
