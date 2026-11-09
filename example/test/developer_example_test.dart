import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';
import 'package:shell_gallery/developer_example.dart';

void main() {
  testWidgets('document selection and settings survive page navigation', (
    tester,
  ) async {
    await tester.pumpWidget(const DeveloperExample());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select brief'));
    await tester.pumpAndSettle();
    expect(find.text('Selection: brief'), findsOneWidget);
    await tester.tap(find.text('Field notes'));
    await tester.pumpAndSettle();
    expect(find.text('Selection: notes'), findsOneWidget);
    await tester.tap(find.text('Settings').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(MacosCheckbox).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Documents').first);
    await tester.pumpAndSettle();
    expect(find.text('Selection: notes'), findsOneWidget);
    expect(
      tester
          .widget<MacosGlassSurface>(find.byType(MacosGlassSurface))
          .forceOpaque,
      isTrue,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
