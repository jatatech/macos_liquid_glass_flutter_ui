import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:shell_gallery/document_inspector.dart';
import 'package:shell_gallery/main.dart';

void main() {
  testWidgets(
    'inspector metadata, keyboard editing, read-only and live previews',
    (tester) async {
      await tester.pumpWidget(
        const MacosApp(
          home: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: DocumentInspector(),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(RatingIndicator));
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(find.text('Editorial rating: 5 of 5'), findsOneWidget);
      await tester.ensureVisible(find.text('Allow metadata edits'));
      await tester.tap(find.byType(MacosCheckbox).at(0));
      await tester.pump();
      expect(
        tester.widget<RatingIndicator>(find.byType(RatingIndicator)).onChanged,
        isNull,
      );
      for (var i = 1; i < 5; i++) {
        await tester.ensureVisible(find.byType(MacosCheckbox).at(i));
        await tester.tap(find.byType(MacosCheckbox).at(i));
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('shell exposes the public inspector entry', (tester) async {
    await tester.pumpWidget(const ShellGallery());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Document inspector'));
    await tester.tap(find.text('Document inspector'));
    await tester.pumpAndSettle();
    expect(find.byType(DocumentInspector), findsOneWidget);
    expect(find.text('Storage used: 72 percent · read only'), findsOneWidget);
  });
}
