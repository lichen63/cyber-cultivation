import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_cultivation/widgets/styled_button.dart';
import 'package:cyber_cultivation/constants.dart';

void main() {
  group('StyledButton', () {
    late AppThemeColors themeColors;

    setUp(() {
      themeColors = AppThemeColors.dark;
    });

    Widget createTestWidget({
      required String text,
      required VoidCallback onPressed,
      double scale = 1.0,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: StyledButton(
            text: text,
            onPressed: onPressed,
            scale: scale,
            themeColors: themeColors,
          ),
        ),
      );
    }

    group('rendering', () {
      testWidgets('displays text correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          text: 'Test Button',
          onPressed: () {},
        ));

        expect(find.text('Test Button'), findsOneWidget);
      });

      testWidgets('renders with dark theme colors', (WidgetTester tester) async {
        themeColors = AppThemeColors.dark;
        await tester.pumpWidget(createTestWidget(
          text: 'Dark Theme',
          onPressed: () {},
        ));

        final textWidget = tester.widget<Text>(find.text('Dark Theme'));
        expect(textWidget.style?.color, AppThemeColors.dark.primaryText);
      });

      testWidgets('renders with light theme colors', (WidgetTester tester) async {
        themeColors = AppThemeColors.light;
        await tester.pumpWidget(createTestWidget(
          text: 'Light Theme',
          onPressed: () {},
        ));

        final textWidget = tester.widget<Text>(find.text('Light Theme'));
        expect(textWidget.style?.color, AppThemeColors.light.primaryText);
      });
    });

    group('interaction', () {
      testWidgets('calls onPressed when tapped', (WidgetTester tester) async {
        bool wasTapped = false;
        await tester.pumpWidget(createTestWidget(
          text: 'Tap Me',
          onPressed: () => wasTapped = true,
        ));

        await tester.tap(find.text('Tap Me'));
        await tester.pump();

        expect(wasTapped, true);
      });

      testWidgets('can be tapped multiple times', (WidgetTester tester) async {
        int tapCount = 0;
        await tester.pumpWidget(createTestWidget(
          text: 'Multi Tap',
          onPressed: () => tapCount++,
        ));

        await tester.tap(find.text('Multi Tap'));
        await tester.tap(find.text('Multi Tap'));
        await tester.tap(find.text('Multi Tap'));
        await tester.pump();

        expect(tapCount, 3);
      });
    });

    group('scaling', () {
      testWidgets('applies scale to text size', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          text: 'Scaled',
          onPressed: () {},
          scale: 0.5,
        ));

        final textWidget = tester.widget<Text>(find.text('Scaled'));
        expect(
          textWidget.style?.fontSize,
          AppConstants.fontSizeButton * 0.5,
        );
      });

      testWidgets('uses default scale of 1.0', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          text: 'Default Scale',
          onPressed: () {},
        ));

        final textWidget = tester.widget<Text>(find.text('Default Scale'));
        expect(
          textWidget.style?.fontSize,
          AppConstants.fontSizeButton,
        );
      });
    });

    group('styling', () {
      testWidgets('has bold text', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          text: 'Bold Text',
          onPressed: () {},
        ));

        final textWidget = tester.widget<Text>(find.text('Bold Text'));
        expect(textWidget.style?.fontWeight, FontWeight.bold);
      });

      testWidgets('has container with correct decoration', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          text: 'Styled',
          onPressed: () {},
        ));

        final container = tester.widget<Container>(
          find.ancestor(
            of: find.text('Styled'),
            matching: find.byType(Container),
          ).first,
        );

        expect(container.decoration, isA<BoxDecoration>());
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, themeColors.overlay);
        expect(decoration.borderRadius, isNotNull);
        expect(decoration.border, isNotNull);
      });
    });
  });
}
