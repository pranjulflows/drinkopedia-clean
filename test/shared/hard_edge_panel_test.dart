import 'package:drinkopedia/app/theme/app_edges.dart';
import 'package:drinkopedia/app/theme/app_theme.dart';
import 'package:drinkopedia/shared/widgets/hard_edge/hard_edge_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpPanel(
    WidgetTester tester, {
    VoidCallback? onTap,
    bool reduceMotion = false,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: Scaffold(
            body: Center(
              child: HardEdgePanel(
                onTap: onTap,
                child: const SizedBox(width: 100, height: 40),
              ),
            ),
          ),
        ),
      ),
    );
  }

  AnimatedContainer panelOf(WidgetTester tester) =>
      tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));

  BoxDecoration decorationOf(WidgetTester tester) =>
      panelOf(tester).decoration! as BoxDecoration;

  testWidgets('a press drops the panel onto its own shadow', (
    WidgetTester tester,
  ) async {
    await pumpPanel(tester, onTap: () {});

    expect(
      decorationOf(tester).boxShadow,
      isNotEmpty,
      reason: 'at rest the shadow is what gives the block its lift',
    );

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(HardEdgePanel)),
    );
    await tester.pump();

    expect(
      decorationOf(tester).boxShadow,
      isEmpty,
      reason: 'pressed, the block sits flat and the shadow goes',
    );
    expect(
      panelOf(tester).transform,
      Matrix4.translationValues(AppEdges.shadow.dx, AppEdges.shadow.dy, 0),
      reason: 'it travels exactly as far as the shadow it lands on',
    );

    await gesture.up();
    await tester.pumpAndSettle();

    expect(decorationOf(tester).boxShadow, isNotEmpty);
    expect(panelOf(tester).transform, Matrix4.translationValues(0, 0, 0));
  });

  testWidgets('a tap still fires after the press animation', (
    WidgetTester tester,
  ) async {
    int taps = 0;
    await pumpPanel(tester, onTap: () => taps++);

    await tester.tap(find.byType(HardEdgePanel));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });

  testWidgets('a panel with no tap handler never moves', (
    WidgetTester tester,
  ) async {
    await pumpPanel(tester);

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(HardEdgePanel)),
    );
    await tester.pump();

    expect(decorationOf(tester).boxShadow, isNotEmpty);
    expect(panelOf(tester).transform, Matrix4.translationValues(0, 0, 0));
    await gesture.up();
  });

  testWidgets('reduce motion keeps the feedback but drops the animation', (
    WidgetTester tester,
  ) async {
    // The press still reads — it just arrives instantly rather than easing.
    await pumpPanel(tester, onTap: () {}, reduceMotion: true);

    expect(panelOf(tester).duration, Duration.zero);
  });
}
