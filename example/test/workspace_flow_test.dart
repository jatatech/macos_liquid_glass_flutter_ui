import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';
import 'package:shell_gallery/dense_content.dart';
import 'package:shell_gallery/document_inspector.dart';

void main() {
  testWidgets(
    'filter recovery, selection, inspection and session save/revert',
    (t) async {
      await t.pumpWidget(
        const MacosApp(
          home: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: DocumentBrowser(),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(
        t
            .widget<PushButton>(
              find.widgetWithText(PushButton, 'Inspect selected document'),
            )
            .onPressed,
        isNull,
      );
      await t.enterText(find.byType(MacosTextField), 'no matching document');
      await t.pumpAndSettle();
      expect(
        t.widget<MacosDataTable>(find.byType(MacosDataTable)).rows,
        isEmpty,
      );
      await t.enterText(find.byType(MacosTextField), 'Design brief');
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('Design brief 1'));
      await t.tap(find.text('Design brief 1'));
      await t.pumpAndSettle();
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.ensureVisible(find.text('Inspect selected document'));
      await t.tap(find.text('Inspect selected document'));
      await t.pumpAndSettle();
      expect(
        t.widget<DocumentInspector>(find.byType(DocumentInspector)).title,
        'Design brief 1',
      );
      await t.ensureVisible(find.byType(RatingIndicator));
      await t.tap(find.byType(RatingIndicator));
      await t.sendKeyEvent(LogicalKeyboardKey.end);
      await t.pump();
      await t.ensureVisible(find.text('Save metadata'));
      await t.tap(find.text('Save metadata'));
      await t.pump();
      expect(find.text('Metadata saved in this session.'), findsOneWidget);
      await t.ensureVisible(find.byType(RatingIndicator));
      await t.tap(find.byType(RatingIndicator));
      await t.sendKeyEvent(LogicalKeyboardKey.home);
      await t.pump();
      await t.ensureVisible(find.text('Revert metadata'));
      await t.tap(find.text('Revert metadata'));
      await t.pump();
      expect(t.widget<RatingIndicator>(find.byType(RatingIndicator)).value, 5);
      expect(find.text('Changes reverted.'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('archive inspection stays read only at narrow 2x text', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(480, 600));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      const MacosApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(480, 600),
            textScaler: TextScaler.linear(2),
            highContrast: true,
            disableAnimations: true,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: DocumentBrowser(),
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Archive'));
    await t.tap(find.text('Archive'));
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Design brief 1'));
    await t.tap(find.text('Design brief 1'));
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Inspect selected document'));
    await t.tap(find.text('Inspect selected document'));
    await t.pumpAndSettle();
    expect(
      t.widget<DocumentInspector>(find.byType(DocumentInspector)).readOnly,
      isTrue,
    );
    expect(
      t.widget<RatingIndicator>(find.byType(RatingIndicator)).onChanged,
      isNull,
    );
    await t.ensureVisible(find.text('Save metadata'));
    expect(
      t
          .widget<PushButton>(find.widgetWithText(PushButton, 'Save metadata'))
          .onPressed,
      isNull,
    );
    expect(t.takeException(), isNull);
  });
}
