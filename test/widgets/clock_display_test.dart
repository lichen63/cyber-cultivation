import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_cultivation/constants.dart';
import 'package:cyber_cultivation/widgets/clock_display.dart';

void main() {
  group('ClockDisplay', () {
    Widget createTestWidget({double scale = 1.0, AppThemeColors? colors}) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: ClockDisplay(
              scale: scale,
              themeColors: colors ?? AppThemeColors.dark,
            ),
          ),
        ),
      );
    }

    testWidgets('renders the current time in the expected format', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      final textWidget = tester.widget<Text>(find.byType(Text));
      expect(
        textWidget.data,
        matches(RegExp(r'^\d{4}-\d{2}-\d{2} [A-Za-z]{3} \d{2}:\d{2}:\d{2}$')),
      );

      // Ensure the timer is cancelled before the test ends.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('keeps ticking once per second without errors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      final textWidget = tester.widget<Text>(find.byType(Text));
      expect(
        textWidget.data,
        matches(RegExp(r'^\d{4}-\d{2}-\d{2} [A-Za-z]{3} \d{2}:\d{2}:\d{2}$')),
      );

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('cancels its timer on dispose', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpWidget(const SizedBox());

      // If the periodic timer were not cancelled, advancing time would surface
      // a "pending timer" failure from the test binding.
      await tester.pump(const Duration(seconds: 3));
      expect(find.byType(ClockDisplay), findsNothing);
    });

    testWidgets('applies window scale to the font size', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(scale: 0.5));

      final textWidget = tester.widget<Text>(find.byType(Text));
      expect(textWidget.style?.fontSize, AppConstants.fontSizeClock * 0.5);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('renders a button-style background box', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(colors: AppThemeColors.dark));

      final container = tester.widget<Container>(
        find
            .ancestor(of: find.byType(Text), matching: find.byType(Container))
            .first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppThemeColors.dark.overlay);
      expect(decoration.border, isNotNull);
      expect(decoration.borderRadius, isNotNull);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('uses the theme primary text color', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(colors: AppThemeColors.light));

      final textWidget = tester.widget<Text>(find.byType(Text));
      expect(textWidget.style?.color, AppThemeColors.light.primaryText);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
