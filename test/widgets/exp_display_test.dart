import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_cultivation/widgets/exp_display.dart';
import 'package:cyber_cultivation/constants.dart';

void main() {
  group('ExpDisplay', () {
    late AppThemeColors themeColors;

    setUp(() {
      themeColors = AppThemeColors.dark;
    });

    Widget createTestWidget({
      required int level,
      required double currentExp,
      required double maxExp,
      double scale = 1.0,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ExpDisplay(
            level: level,
            currentExp: currentExp,
            maxExp: maxExp,
            scale: scale,
            themeColors: themeColors,
          ),
        ),
      );
    }

    group('level display', () {
      testWidgets('displays level correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          level: 10,
          currentExp: 0,
          maxExp: 100,
        ));

        expect(find.text('Lv. 10'), findsOneWidget);
      });

      testWidgets('displays level 1', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          level: 1,
          currentExp: 0,
          maxExp: 100,
        ));

        expect(find.text('Lv. 1'), findsOneWidget);
      });

      testWidgets('displays high level', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          level: 999,
          currentExp: 0,
          maxExp: 100,
        ));

        expect(find.text('Lv. 999'), findsOneWidget);
      });
    });

    group('exp display formatting', () {
      testWidgets('displays simple exp correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          level: 1,
          currentExp: 50,
          maxExp: 100,
        ));

        expect(find.text('50 / 100'), findsOneWidget);
      });

      testWidgets('displays K suffix for thousands', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          level: 1,
          currentExp: 15000,
          maxExp: 30000,
        ));

        expect(find.text('15.0K / 30.0K'), findsOneWidget);
      });

      testWidgets('displays M suffix for millions', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          level: 1,
          currentExp: 1500000,
          maxExp: 3000000,
        ));

        expect(find.text('1.5M / 3.0M'), findsOneWidget);
      });

      testWidgets('displays B suffix for billions', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          level: 1,
          currentExp: 2500000000,
          maxExp: 5000000000,
        ));

        expect(find.text('2.5B / 5.0B'), findsOneWidget);
      });

      testWidgets('displays T suffix for trillions', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          level: 1,
          currentExp: 1000000000000,
          maxExp: 2000000000000,
        ));

        expect(find.text('1.0T / 2.0T'), findsOneWidget);
      });

      testWidgets('displays infinity symbol for infinite maxExp', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          level: 1,
          currentExp: 100,
          maxExp: double.infinity,
        ));

        expect(find.text('∞ / ∞'), findsOneWidget);
      });
    });

    group('progress bar', () {
      testWidgets('renders progress indicator', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          level: 1,
          currentExp: 50,
          maxExp: 100,
        ));

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('shows 50% progress correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          level: 1,
          currentExp: 50,
          maxExp: 100,
        ));

        final progressIndicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );

        expect(progressIndicator.value, 0.5);
      });

      testWidgets('shows 0% progress correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          level: 1,
          currentExp: 0,
          maxExp: 100,
        ));

        final progressIndicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );

        expect(progressIndicator.value, 0.0);
      });

      testWidgets('shows 100% progress correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          level: 1,
          currentExp: 100,
          maxExp: 100,
        ));

        final progressIndicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );

        expect(progressIndicator.value, 1.0);
      });

      testWidgets('clamps overflow exp to 100%', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          level: 1,
          currentExp: 150,
          maxExp: 100,
        ));

        final progressIndicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );

        expect(progressIndicator.value, 1.0);
      });

      testWidgets('shows 100% progress for infinite maxExp', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          level: 1,
          currentExp: 100,
          maxExp: double.infinity,
        ));

        final progressIndicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );

        expect(progressIndicator.value, 1.0);
      });
    });

    group('theming', () {
      testWidgets('uses dark theme colors', (WidgetTester tester) async {
        themeColors = AppThemeColors.dark;
        await tester.pumpWidget(createTestWidget(
          level: 1,
          currentExp: 50,
          maxExp: 100,
        ));

        final levelText = tester.widget<Text>(find.text('Lv. 1'));
        expect(levelText.style?.color, AppThemeColors.dark.primaryText);
      });

      testWidgets('uses light theme colors', (WidgetTester tester) async {
        themeColors = AppThemeColors.light;
        await tester.pumpWidget(createTestWidget(
          level: 1,
          currentExp: 50,
          maxExp: 100,
        ));

        final levelText = tester.widget<Text>(find.text('Lv. 1'));
        expect(levelText.style?.color, AppThemeColors.light.primaryText);
      });
    });

    group('scaling', () {
      testWidgets('applies scale to level text', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          level: 1,
          currentExp: 50,
          maxExp: 100,
          scale: 0.5,
        ));

        final levelText = tester.widget<Text>(find.text('Lv. 1'));
        expect(levelText.style?.fontSize, AppConstants.fontSizeLevel * 0.5);
      });

      testWidgets('applies scale to exp text', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          level: 1,
          currentExp: 50,
          maxExp: 100,
          scale: 0.5,
        ));

        final expText = tester.widget<Text>(find.text('50 / 100'));
        expect(expText.style?.fontSize, AppConstants.fontSizeExpProgress * 0.5);
      });

      testWidgets('uses default scale of 1.0', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          level: 1,
          currentExp: 50,
          maxExp: 100,
        ));

        final levelText = tester.widget<Text>(find.text('Lv. 1'));
        expect(levelText.style?.fontSize, AppConstants.fontSizeLevel);
      });
    });

    group('layout', () {
      testWidgets('uses Row for layout', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          level: 1,
          currentExp: 50,
          maxExp: 100,
        ));

        expect(find.byType(Row), findsOneWidget);
      });

      testWidgets('has correct minimum size', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          level: 1,
          currentExp: 50,
          maxExp: 100,
        ));

        // Verify the Row has mainAxisSize.min
        final row = tester.widget<Row>(find.byType(Row));
        expect(row.mainAxisSize, MainAxisSize.min);
      });
    });
  });
}
