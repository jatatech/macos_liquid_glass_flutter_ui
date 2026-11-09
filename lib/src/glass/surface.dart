import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';
import 'package:macos_liquid_glass_ui/src/utils/native_occlusion.dart';
import 'package:macos_liquid_glass_ui/src/platform/glass.dart';

/// A bounded glass region. [child] is Flutter content, never hosted by AppKit.
///
/// Providing [nativeCommands] opts into the bounded AppKit command host instead
/// of [child] on supported macOS. It must describe the same actions as [child].
/// Without that descriptor arbitrary Flutter children use approximation, even
/// on macOS: native sibling clipping/stacking cannot host Flutter widgets.
/// Missing macOS transport, unsupported OS/composition and accessibility select
/// opaque. Custom visual overlays must set [nativeOccluded]. Single window only.
class MacosGlassSurface extends StatefulWidget {
  const MacosGlassSurface({
    super.key,
    required this.child,
    this.nativeCommands = const [],
    this.forceOpaque = false,
    this.nativeOccluded = false,
    this.focusNode,
    this.onRenderingChanged,
  });

  final Widget child;
  final List<MacosGlassCommand> nativeCommands;
  final bool forceOpaque;
  final bool nativeOccluded;

  /// Caller-owned entry node for the native command host.
  final FocusNode? focusNode;
  final ValueChanged<MacosGlassRendering>? onRenderingChanged;

  @override
  State<MacosGlassSurface> createState() => _GlassSurfaceState();
}

class _GlassSurfaceState extends State<MacosGlassSurface>
    with WidgetsBindingObserver {
  final _anchor = GlobalKey();
  final _ownedFocus = FocusNode(debugLabel: 'Native glass commands');
  FocusNode get _focus => widget.focusNode ?? _ownedFocus;
  bool _leaving = false;
  final int _id = MacosGlassBridge.nextId++;
  Future<void> _pending = Future<void>.value();
  String? _lastSpec;
  // Identity distinguishes an invalidation retry with the same wire payload.
  Map<String, Object?>? _desiredSpec;
  Map<String, Object?>? _queuedSpec;
  bool _updating = false;
  bool _native = false;
  MacosGlassRendering _reported = MacosGlassRendering.opaque;
  bool _bridgeRegistered = false;
  bool _visible = false;
  bool _failed = false;
  bool _permitted = false;
  bool _scheduled = false;
  bool _resumed = true;
  bool _dark = false;
  bool _motion = false;
  double _fontSize = 13;
  List<Animation<double>> _routeAnimations = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bridgeRegistered =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
    if (_bridgeRegistered) {
      MacosGlassBridge.owners[_id] = _receive;
      MacosGlassBridge.install();
    }
    NativeGlassOcclusion.count.addListener(_schedule);
    WidgetsBinding.instance.addPostFrameCallback(_observeFrame);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final animation in _routeAnimations) {
      animation.removeListener(_schedule);
    }
    final route = ModalRoute.of(context);
    _routeAnimations = [
      if (route?.animation != null) route!.animation!,
      if (route?.secondaryAnimation != null) route!.secondaryAnimation!,
    ];
    for (final animation in _routeAnimations) {
      animation.addListener(_schedule);
    }
  }

  // Observe frames the application already requests; never drive a frame loop.
  void _observeFrame(Duration _) {
    if (!mounted) return;
    _sync();
    WidgetsBinding.instance.addPostFrameCallback(_observeFrame);
  }

  Future<void> _enterNative() async {
    if (_leaving || !_native || !_permitted || !_focus.hasFocus) return;
    try {
      final entered = await MacosGlassBridge.channel.invokeMethod<Object?>(
        'focus',
        {'id': _id, 'backward': HardwareKeyboard.instance.isShiftPressed},
      );
      if (entered != true) _failFocus();
    } on PlatformException {
      _failFocus();
    } on MissingPluginException {
      _failFocus();
    }
  }

  void _failFocus() {
    if (!mounted) return;
    _failed = true;
    _lastSpec = null;
    _desiredSpec = null;
    _setNative(false);
    _schedule();
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _receive(MethodCall call) {
    if (!mounted) return;
    final args = call.arguments;
    if (call.method == 'exitFocus' &&
        args is Map &&
        args['backward'] is bool &&
        _native &&
        _permitted) {
      _leaving = true;
      _focus.requestFocus();
      if (args['backward'] == true) {
        _focus.previousFocus();
      } else {
        _focus.nextFocus();
      }
      _leaving = false;
    } else if (call.method == 'action' && args is Map && args['index'] is int) {
      final index = args['index'] as int;
      if (_native &&
          _permitted &&
          _visible &&
          _resumed &&
          index >= 0 &&
          index < widget.nativeCommands.length) {
        widget.nativeCommands[index].onPressed?.call();
      }
    } else if (call.method == 'invalidated') {
      _lastSpec = null;
      _desiredSpec = null;
      _failed = false;
      _setNative(false);
      _schedule();
      WidgetsBinding.instance.ensureVisualUpdate();
    }
  }

  void _setNative(bool value) {
    if (!mounted || value == _native) return;
    setState(() => _native = value);
  }

  void _schedule() {
    if (_scheduled || !mounted) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (mounted) _sync();
    });
  }

  void _sync() {
    if (!_bridgeRegistered) return;
    final box = _anchor.currentContext?.findRenderObject() as RenderBox?;
    Rect? rect;
    if (box != null && box.attached && box.hasSize) {
      rect = box.localToGlobal(Offset.zero) & box.size;
      final transform = box.getTransformTo(null).storage;
      for (var index = 0; index < 16; index++) {
        if (index == 12 || index == 13) {
          continue; // Translation is synchronized.
        }
        final expected = index % 5 == 0 ? 1.0 : 0.0;
        if ((transform[index] - expected).abs() > 0.00001) {
          rect = null;
        }
      }
      RenderObject? ancestor = box;
      while (ancestor != null) {
        if ((ancestor is RenderOffstage && ancestor.offstage) ||
            (ancestor is RenderOpacity && ancestor.opacity < 1) ||
            (ancestor is RenderIgnorePointer && ancestor.ignoring) ||
            (ancestor is RenderExcludeSemantics && ancestor.excluding) ||
            ancestor is RenderClipPath ||
            ancestor is RenderClipOval) {
          rect = null;
          break;
        }
        ancestor = ancestor.parent;
      }
      // A pointer-blocking overlay or ancestor clip must not leave native hits
      // above hidden Flutter content. All corners must reach our anchor listener.
      if (rect != null) {
        for (final point in [
          rect.topLeft + const Offset(1, 1),
          rect.bottomRight - const Offset(1, 1),
          rect.topRight + const Offset(-1, 1),
          rect.bottomLeft + const Offset(1, -1),
          rect.center,
        ]) {
          final hit = HitTestResult();
          WidgetsBinding.instance.hitTestInView(
            hit,
            point,
            View.of(context).viewId,
          );
          if (!hit.path.any((entry) => entry.target == box)) {
            rect = null;
            break;
          }
        }
      }
    }
    final view = View.of(context);
    final bounds = Offset.zero & (view.physicalSize / view.devicePixelRatio);
    final show =
        _permitted &&
        !_failed &&
        NativeGlassOcclusion.count.value == 0 &&
        _resumed &&
        rect != null &&
        bounds.contains(rect.topLeft) &&
        bounds.contains(rect.bottomRight);
    _visible = show;
    final spec = <String, Object?>{
      'id': _id,
      'show': show,
      if (show) ...{
        'x': rect.left,
        'y': rect.top,
        'width': rect.width,
        'height': rect.height,
        'radius': MacosGlassData.commandRadius,
        'dark': _dark,
        'reduceMotion': _motion,
        'fontSize': _fontSize,
        'commands': [
          for (final command in widget.nativeCommands)
            {'label': command.label, 'enabled': command.onPressed != null},
        ],
      },
    };
    final encoded = jsonEncode(spec);
    if (_lastSpec == encoded) return;
    _lastSpec = encoded;
    _desiredSpec = spec;
    // Keep only the latest unsent state while a channel reply is outstanding.
    _queuedSpec = spec;
    if (!_updating) {
      _updating = true;
      _pending = _drainUpdates();
    }
  }

  Future<void> _drainUpdates() async {
    while (mounted && _queuedSpec != null) {
      final spec = _queuedSpec!;
      _queuedSpec = null;
      if (!identical(_desiredSpec, spec)) continue;
      final show = spec['show'] == true;
      try {
        final active = await MacosGlassBridge.channel.invokeMethod<Object?>(
          'update',
          spec,
        );
        if (!mounted || !identical(_desiredSpec, spec)) continue;
        if (show && active != true) _failed = true;
        _setNative(show && active == true);
      } on PlatformException {
        if (!mounted || !identical(_desiredSpec, spec)) continue;
        _failed = true;
        _setNative(false);
      } on MissingPluginException {
        if (!mounted || !identical(_desiredSpec, spec)) continue;
        _failed = true;
        _setNative(false);
      }
    }
    _updating = false;
  }

  @override
  void didChangeMetrics() => _schedule();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    _schedule();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ownedFocus.dispose();
    NativeGlassOcclusion.count.removeListener(_schedule);
    for (final animation in _routeAnimations) {
      animation.removeListener(_schedule);
    }
    MacosGlassBridge.owners.remove(_id);
    _queuedSpec = null;
    // Removal must follow any in-flight creation; no unsent update survives.
    unawaited(
      _pending.then((_) async {
        try {
          if (_bridgeRegistered) {
            await MacosGlassBridge.channel.invokeMethod<void>('remove', {
              'id': _id,
            });
          }
        } on PlatformException {
          // Native window/engine teardown may already have released the owner.
        } on MissingPluginException {
          // The Flutter fallback requires no native cleanup.
        }
      }),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final preferences = MacosAccessibility.of(context);
    assert(widget.nativeCommands.length <= 4);
    _dark = MacosTheme.of(context).brightness == Brightness.dark;
    _motion = media.disableAnimations || preferences.reduceMotion;
    _fontSize = media.textScaler.scale(13);
    return LayoutBuilder(
      builder: (context, constraints) {
        assert(constraints.hasBoundedWidth);
        final permitted =
            !kIsWeb &&
            defaultTargetPlatform == TargetPlatform.macOS &&
            widget.nativeCommands.isNotEmpty &&
            !widget.forceOpaque &&
            !widget.nativeOccluded &&
            TickerMode.valuesOf(context).enabled &&
            (ModalRoute.of(context)?.isCurrent ?? true) &&
            MacosGlassData.permitsNative(
              accessibility: preferences,
              media: media,
              direction: Directionality.of(context),
              width: constraints.maxWidth,
            );
        if (permitted && !_permitted) _failed = false;
        _permitted = permitted;
        _schedule();
        final showNative = _native && _permitted;
        final mode = MacosGlassData.rendering(
          platform: defaultTargetPlatform,
          web: kIsWeb,
          accessibility: preferences,
          media: media,
          forceOpaque: widget.forceOpaque,
          nativeActive: showNative,
          nativeRequested: widget.nativeCommands.isNotEmpty,
        );
        if (mode != _reported) {
          _reported = mode;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _reported == mode) {
              widget.onRenderingChanged?.call(mode);
            }
          });
        }
        return Listener(
          key: _anchor,
          behavior: HitTestBehavior.translucent,
          child: Stack(
            fit: StackFit.passthrough,
            alignment: Alignment.center,
            children: [
              // Retain the native host's minimum anchor height while awaiting
              // capability or rendering Flutter controls; avoid a mount jump.
              if (!showNative && widget.nativeCommands.isNotEmpty)
                const SizedBox(
                  height: MacosGlassData.commandHeight,
                  width: double.infinity,
                ),
              if (showNative)
                Focus(
                  focusNode: _focus,
                  canRequestFocus: widget.nativeCommands.any(
                    (command) => command.onPressed != null,
                  ),
                  onFocusChange: (focused) {
                    if (focused) unawaited(_enterNative());
                  },
                  child: const SizedBox(
                    height: MacosGlassData.commandHeight,
                    width: double.infinity,
                  ),
                )
              else
                _FlutterGlass(mode: mode, child: widget.child),
            ],
          ),
        );
      },
    );
  }
}

/// Static decoration: no animation to suppress under Reduce Motion. Each surface
/// clips its own filter; nested surfaces skip blur rather than stacking filters.
class _FlutterGlass extends StatelessWidget {
  const _FlutterGlass({required this.mode, required this.child});
  final MacosGlassRendering mode;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final chrome = MacosChromeData.of(context);
    final dark = MacosTheme.of(context).brightness == Brightness.dark;
    final approximate = mode == MacosGlassRendering.approximation;
    final decoration = BoxDecoration(
      color: approximate ? MacosGlassData.tint(dark) : chrome.toolbar,
      border: Border.all(
        color: approximate ? MacosGlassData.edge(dark) : chrome.separator,
      ),
      borderRadius: BorderRadius.circular(MacosGlassData.commandRadius),
      gradient: approximate ? MacosGlassData.highlight(dark) : null,
    );
    final content = DecoratedBox(decoration: decoration, child: child);
    final nested =
        context.findAncestorWidgetOfExactType<_FlutterGlass>() != null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(MacosGlassData.commandRadius),
      child: approximate && !nested
          ? BackdropFilter(
              filter: ui.ImageFilter.blur(
                sigmaX: MacosGlassData.blurSigma,
                sigmaY: MacosGlassData.blurSigma,
              ),
              child: content,
            )
          : content,
    );
  }
}
