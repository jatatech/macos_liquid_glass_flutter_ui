import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Watches an immutable popup anchor on frames already requested by the app.
/// It never drives a frame loop, and cancellation invalidates queued callbacks.
class TransientAnchorWatch {
  TransientAnchorWatch(this.context, this.onInvalidated);
  final BuildContext Function() context;
  final VoidCallback onInvalidated;
  int _generation = 0;

  void cancel() => _generation++;

  void watch() {
    final generation = ++_generation;
    final initial = _rect();
    void check(Duration _) {
      if (generation != _generation) return;
      if (initial == null || _rect() != initial) {
        cancel();
        onInvalidated();
      } else {
        WidgetsBinding.instance.addPostFrameCallback(check);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback(check);
  }

  Rect? _rect() {
    final ctx = context();
    if (!ctx.mounted) return null;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    RenderObject? ancestor = box;
    while (ancestor != null) {
      if (ancestor is RenderOffstage && ancestor.offstage) return null;
      if (ancestor is RenderOpacity && ancestor.opacity == 0) return null;
      ancestor = ancestor.parent;
    }
    return box.localToGlobal(Offset.zero) & box.size;
  }
}
