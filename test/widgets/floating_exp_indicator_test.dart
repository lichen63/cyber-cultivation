import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_cultivation/widgets/floating_exp_indicator.dart';
import 'package:cyber_cultivation/constants.dart';

void main() {
  group('FloatingExpIndicatorManager', () {
    late GlobalKey<FloatingExpIndicatorManagerState> indicatorKey;

    setUp(() {
      indicatorKey = GlobalKey<FloatingExpIndicatorManagerState>();
    });

    testWidgets('should not show any indicators initially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingExpIndicatorManager(
              key: indicatorKey,
              themeColors: AppThemeColors.dark,
            ),
          ),
        ),
      );

      // No exp text should be visible initially
      expect(find.textContaining('EXP'), findsNothing);
    });

    testWidgets('should show indicator when exp is added', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingExpIndicatorManager(
              key: indicatorKey,
              themeColors: AppThemeColors.dark,
            ),
          ),
        ),
      );

      // Add exp gain
      indicatorKey.currentState?.addExpGain(100);
      await tester.pump();

      // Indicator should be visible
      expect(find.textContaining('+100 EXP'), findsOneWidget);
    });

    testWidgets('should format large numbers correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingExpIndicatorManager(
              key: indicatorKey,
              themeColors: AppThemeColors.dark,
            ),
          ),
        ),
      );

      // Test K suffix
      indicatorKey.currentState?.addExpGain(1500);
      await tester.pump();
      expect(find.textContaining('+1.5K EXP'), findsOneWidget);

      // Wait for queue interval
      await tester.pump(AppConstants.floatingExpQueueInterval);
    });

    testWidgets('indicator should disappear after animation completes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingExpIndicatorManager(
              key: indicatorKey,
              themeColors: AppThemeColors.dark,
            ),
          ),
        ),
      );

      indicatorKey.currentState?.addExpGain(50);
      await tester.pump();

      expect(find.textContaining('EXP'), findsOneWidget);

      // Wait for animation to complete
      await tester.pumpAndSettle(AppConstants.floatingExpDuration);

      // Indicator should be gone
      expect(find.textContaining('EXP'), findsNothing);
    });

    testWidgets('should queue multiple rapid exp gains', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingExpIndicatorManager(
              key: indicatorKey,
              themeColors: AppThemeColors.dark,
            ),
          ),
        ),
      );

      // Add multiple exp gains rapidly
      indicatorKey.currentState?.addExpGain(10);
      indicatorKey.currentState?.addExpGain(20);
      indicatorKey.currentState?.addExpGain(30);
      await tester.pump();

      // First one should show immediately
      expect(find.textContaining('+10 EXP'), findsOneWidget);

      // Wait for queue interval
      await tester.pump(AppConstants.floatingExpQueueInterval);

      // Second one should now show
      expect(find.textContaining('+20 EXP'), findsOneWidget);
    });

    testWidgets('should work with light theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingExpIndicatorManager(
              key: indicatorKey,
              themeColors: AppThemeColors.light,
            ),
          ),
        ),
      );

      indicatorKey.currentState?.addExpGain(75);
      await tester.pump();

      expect(find.textContaining('+75 EXP'), findsOneWidget);
    });

    testWidgets('should handle decimal exp values', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingExpIndicatorManager(
              key: indicatorKey,
              themeColors: AppThemeColors.dark,
            ),
          ),
        ),
      );

      indicatorKey.currentState?.addExpGain(10.5);
      await tester.pump();

      expect(find.textContaining('+10.5 EXP'), findsOneWidget);
    });
  });

  group('Floating Exp Constants', () {
    test('should have valid animation duration', () {
      expect(AppConstants.floatingExpDuration.inMilliseconds, greaterThan(0));
    });

    test('should have valid queue settings', () {
      expect(
        AppConstants.floatingExpQueueInterval.inMilliseconds,
        greaterThan(0),
      );
      expect(AppConstants.floatingExpMaxQueueSize, greaterThan(0));
    });

    test('should have valid visual settings', () {
      expect(AppConstants.floatingExpDistance, greaterThan(0));
      expect(AppConstants.floatingExpStartOffset, greaterThanOrEqualTo(0));
      expect(AppConstants.floatingExpPaddingHorizontal, greaterThan(0));
      expect(AppConstants.floatingExpPaddingVertical, greaterThan(0));
      expect(AppConstants.floatingExpBorderWidth, greaterThan(0));
      expect(AppConstants.floatingExpShadowBlur, greaterThan(0));
      expect(AppConstants.fontSizeFloatingExp, greaterThan(0));
    });
  });
}
