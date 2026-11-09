import 'package:flutter_test/flutter_test.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';

void main() {
  test('MacosColors lerp', () {
    expect(
      MacosColor.lerp(MacosColors.appleBlue, MacosColors.appleRed, 1),
      MacosColors.appleRed,
    );
  });
}
