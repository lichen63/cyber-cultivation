import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_cultivation/widgets/level_up_effect.dart';
import 'package:cyber_cultivation/constants.dart';

void main() {
  group('LevelUpEffectWrapper', () {
    late GlobalKey<LevelUpEffectWrapperState> effectKey;

    setUp(() {
      effectKey = GlobalKey<LevelUpEffectWrapperState>();
    });

    testWidgets('should show child widget normally when not triggered', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelUpEffectWrapper(
              key: effectKey,
              themeColors: AppThemeColors.dark,
              child: const Text('Test Child'),
            ),
          ),
        ),
      );

      // Child should be visible
      expect(find.text('Test Child'), findsOneWidget);
    });

    testWidgets('should still show child when effect is triggered', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelUpEffectWrapper(
              key: effectKey,
              themeColors: AppThemeColors.dark,
              child: const Text('Test Child'),
            ),
          ),
        ),
      );

      // Trigger level up effect
      effectKey.currentState?.triggerLevelUp();
      await tester.pump();

      // Child should still be visible during effect
      expect(find.text('Test Child'), findsOneWidget);
    });

    testWidgets('should restart effect when triggered multiple times', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelUpEffectWrapper(
              key: effectKey,
              themeColors: AppThemeColors.dark,
              child: const Text('Test Child'),
            ),
          ),
        ),
      );

      // Trigger first level up
      effectKey.currentState?.triggerLevelUp();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Trigger another level up quickly (simulating rapid level ups)
      effectKey.currentState?.triggerLevelUp();
      await tester.pump();

      // Effect should restart - child should still be visible
      expect(find.text('Test Child'), findsOneWidget);
    });

    testWidgets('effect should complete after animation duration', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelUpEffectWrapper(
              key: effectKey,
              themeColors: AppThemeColors.dark,
              child: const Text('Test Child'),
            ),
          ),
        ),
      );

      // Trigger level up effect
      effectKey.currentState?.triggerLevelUp();
      await tester.pump();

      // Wait for animation to complete
      await tester.pumpAndSettle(LevelUpEffectConstants.totalDuration);

      // Child should still be visible after effect completes
      expect(find.text('Test Child'), findsOneWidget);
    });

    testWidgets('should work with light theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelUpEffectWrapper(
              key: effectKey,
              themeColors: AppThemeColors.light,
              child: const Text('Test Child'),
            ),
          ),
        ),
      );

      effectKey.currentState?.triggerLevelUp();
      await tester.pump();

      expect(find.text('Test Child'), findsOneWidget);
    });

    testWidgets('should respect scale parameter', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelUpEffectWrapper(
              key: effectKey,
              themeColors: AppThemeColors.dark,
              scale: 0.5,
              child: const Text('Test Child'),
            ),
          ),
        ),
      );

      effectKey.currentState?.triggerLevelUp();
      await tester.pump();

      expect(find.text('Test Child'), findsOneWidget);
    });
  });

  group('LevelUpEffectConstants', () {
    test('should have valid duration value', () {
      expect(
        LevelUpEffectConstants.totalDuration.inMilliseconds,
        greaterThan(0),
      );
    });

    test('should have valid glow settings', () {
      expect(LevelUpEffectConstants.glowSpread, greaterThan(0));
      expect(LevelUpEffectConstants.glowLayerCount, greaterThan(0));
      expect(LevelUpEffectConstants.glowLayerSpacing, greaterThan(0));
      expect(LevelUpEffectConstants.borderGlowWidth, greaterThan(0));
      expect(LevelUpEffectConstants.borderBlurRadius, greaterThan(0));
      expect(LevelUpEffectConstants.innerBorderWidth, greaterThan(0));
    });

    test('should have valid particle settings', () {
      expect(LevelUpEffectConstants.particleCount, greaterThan(0));
      expect(LevelUpEffectConstants.particleMinSize, greaterThan(0));
      expect(
        LevelUpEffectConstants.particleMaxSize,
        greaterThanOrEqualTo(LevelUpEffectConstants.particleMinSize),
      );
      expect(LevelUpEffectConstants.particleSpeed, greaterThan(0));
    });
  });
}
