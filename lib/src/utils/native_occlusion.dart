import 'package:flutter/foundation.dart';

/// Package-owned non-interactive overlays cannot be detected by pointer probes.
/// Count owners so overlapping tooltips cannot restore glass prematurely.
class NativeGlassOcclusion {
  static final count = ValueNotifier<int>(0);
}
