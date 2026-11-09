import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';

void main() {
  testWidgets(
    'retains controller and offset across rebuild and disposes on removal',
    (tester) async {
      ScrollController? controller;
      late StateSetter rebuild;
      await tester.pumpWidget(
        MacosApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return ContentArea(
                builder: (context, scroll) {
                  controller = scroll;
                  return ListView(
                    controller: scroll,
                    children: List.generate(
                      100,
                      (i) => SizedBox(height: 50, child: Text('Row $i')),
                    ),
                  );
                },
              );
            },
          ),
        ),
      );
      final first = controller!;
      first.jumpTo(300);
      rebuild(() {});
      await tester.pump();
      expect(controller, same(first));
      expect(controller!.offset, 300);
      await tester.pumpWidget(const SizedBox());
      expect(() => first.addListener(() {}), throwsFlutterError);
    },
  );

  testWidgets(
    'documented null builder renders empty and can become scrollable',
    (tester) async {
      await tester.pumpWidget(const MacosApp(home: ContentArea(builder: null)));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        MacosApp(
          home: ContentArea(
            builder: (_, controller) => ListView(
              controller: controller,
              children: const [Text('Ready')],
            ),
          ),
        ),
      );
      expect(find.text('Ready'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
