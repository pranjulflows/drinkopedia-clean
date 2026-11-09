import 'package:drinkopedia/app/theme/app_theme.dart';
import 'package:drinkopedia/features/spirits/presentation/widgets/spirit_message.dart';
import 'package:drinkopedia/shared/widgets/hard_edge/hard_edge_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpMessage(WidgetTester tester, {bool dark = false}) {
    return tester.pumpWidget(
      MaterialApp(
        theme: dark ? AppTheme.dark() : AppTheme.light(),
        home: const Scaffold(
          body: SpiritMessage(
            icon: Icons.cloud_off_outlined,
            title: 'Something went wrong',
            message: 'No connection',
          ),
        ),
      ),
    );
  }

  /// The decoration actually painted behind the icon.
  BoxDecoration iconDecoration(WidgetTester tester) {
    final Finder box = find
        .descendant(
          of: find.byType(HardEdgePanel),
          matching: find.byType(DecoratedBox),
        )
        .first;
    return tester.widget<DecoratedBox>(box).decoration as BoxDecoration;
  }

  testWidgets('the icon block is filled, so its shadow cannot show through', (
    WidgetTester tester,
  ) async {
    // Regression: the block was a bordered box with a hard offset shadow and
    // no fill. The shadow is a solid rectangle rather than a blur, so it
    // painted straight through the transparent box and the ink icon landed on
    // ink — the whole thing rendered as a black square.
    await pumpMessage(tester);

    final BoxDecoration decoration = iconDecoration(tester);
    expect(decoration.boxShadow, isNotNull);
    expect(decoration.boxShadow, isNotEmpty);
    expect(
      decoration.color,
      isNotNull,
      reason: 'a hard shadow behind an unfilled box swallows its own content',
    );
    expect(decoration.color!.a, greaterThan(0));
    expect(
      decoration.color,
      isNot(decoration.boxShadow!.first.color),
      reason: 'fill and shadow must differ or the block reads as one mass',
    );
  });

  testWidgets('holds up in dark mode too', (WidgetTester tester) async {
    await pumpMessage(tester, dark: true);

    final BoxDecoration decoration = iconDecoration(tester);
    expect(decoration.color, isNotNull);
    expect(decoration.color, isNot(decoration.boxShadow!.first.color));
  });

  testWidgets('renders the title and message', (WidgetTester tester) async {
    await pumpMessage(tester);

    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    expect(find.text('SOMETHING WENT WRONG'), findsOneWidget);
    expect(find.text('No connection'), findsOneWidget);
  });
}
