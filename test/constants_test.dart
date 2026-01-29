import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_cultivation/constants.dart';

void main() {
  group('AppThemeMode', () {
    test('has correct values', () {
      expect(AppThemeMode.values.length, 2);
      expect(AppThemeMode.light.name, 'light');
      expect(AppThemeMode.dark.name, 'dark');
    });
  });

  group('AppThemeColors', () {
    group('dark theme', () {
      test('has correct brightness', () {
        expect(AppThemeColors.dark.brightness, Brightness.dark);
      });

      test('has white primary text', () {
        expect(AppThemeColors.dark.primaryText, Colors.white);
      });

      test('has all required colors defined', () {
        final dark = AppThemeColors.dark;
        expect(dark.primaryText, isNotNull);
        expect(dark.secondaryText, isNotNull);
        expect(dark.background, isNotNull);
        expect(dark.dialogBackground, isNotNull);
        expect(dark.overlay, isNotNull);
        expect(dark.overlayLight, isNotNull);
        expect(dark.border, isNotNull);
        expect(dark.accent, isNotNull);
        expect(dark.accentSecondary, isNotNull);
        expect(dark.inactive, isNotNull);
        expect(dark.error, isNotNull);
        expect(dark.expBarBackground, isNotNull);
        expect(dark.expBarText, isNotNull);
        expect(dark.expBarTextShadow, isNotNull);
        expect(dark.levelTextShadow, isNotNull);
        expect(dark.progressBarFill, isNotNull);
        expect(dark.chartAccent, isNotNull);
        expect(dark.networkUpload, isNotNull);
        expect(dark.networkDownload, isNotNull);
      });
    });

    group('light theme', () {
      test('has correct brightness', () {
        expect(AppThemeColors.light.brightness, Brightness.light);
      });

      test('has dark primary text', () {
        expect(AppThemeColors.light.primaryText, isNot(Colors.white));
      });

      test('has all required colors defined', () {
        final light = AppThemeColors.light;
        expect(light.primaryText, isNotNull);
        expect(light.secondaryText, isNotNull);
        expect(light.background, isNotNull);
        expect(light.dialogBackground, isNotNull);
        expect(light.overlay, isNotNull);
        expect(light.overlayLight, isNotNull);
        expect(light.border, isNotNull);
        expect(light.accent, isNotNull);
        expect(light.accentSecondary, isNotNull);
        expect(light.inactive, isNotNull);
        expect(light.error, isNotNull);
        expect(light.expBarBackground, isNotNull);
        expect(light.expBarText, isNotNull);
        expect(light.expBarTextShadow, isNotNull);
        expect(light.levelTextShadow, isNotNull);
        expect(light.progressBarFill, isNotNull);
        expect(light.chartAccent, isNotNull);
        expect(light.networkUpload, isNotNull);
        expect(light.networkDownload, isNotNull);
      });
    });

    group('fromMode', () {
      test('returns dark colors for dark mode', () {
        final colors = AppThemeColors.fromMode(AppThemeMode.dark);
        expect(colors, AppThemeColors.dark);
      });

      test('returns light colors for light mode', () {
        final colors = AppThemeColors.fromMode(AppThemeMode.light);
        expect(colors, AppThemeColors.light);
      });
    });
  });

  group('AppConstants', () {
    group('app info', () {
      test('has app title', () {
        expect(AppConstants.appTitle, 'Cyber Cultivation');
      });
    });

    group('window configuration', () {
      test('has valid default dimensions', () {
        expect(AppConstants.defaultWindowWidth, greaterThan(0));
        expect(AppConstants.defaultWindowHeight, greaterThan(0));
      });

      test('has valid min dimensions', () {
        expect(AppConstants.minWindowWidth, greaterThan(0));
        expect(AppConstants.minWindowHeight, greaterThan(0));
        expect(AppConstants.minWindowWidth, lessThanOrEqualTo(AppConstants.defaultWindowWidth));
        expect(AppConstants.minWindowHeight, lessThanOrEqualTo(AppConstants.defaultWindowHeight));
      });

      test('has valid max dimensions', () {
        expect(AppConstants.maxWindowWidth, greaterThan(AppConstants.defaultWindowWidth));
        expect(AppConstants.maxWindowHeight, greaterThan(AppConstants.defaultWindowHeight));
      });

      test('aspect ratio is positive', () {
        expect(AppConstants.windowAspectRatio, greaterThan(0));
      });
    });

    group('UI dimensions', () {
      test('border values are positive', () {
        expect(AppConstants.borderWidth, greaterThan(0));
        expect(AppConstants.thinBorderWidth, greaterThan(0));
        expect(AppConstants.borderRadius, greaterThan(0));
        expect(AppConstants.smallBorderRadius, greaterThan(0));
      });

      test('padding is positive', () {
        expect(AppConstants.defaultPadding, greaterThan(0));
        expect(AppConstants.buttonPaddingHorizontal, greaterThanOrEqualTo(0));
      });

      test('exp bar dimensions are positive', () {
        expect(AppConstants.expBarHeight, greaterThan(0));
        expect(AppConstants.expBarWidth, greaterThan(0));
        expect(AppConstants.expBarBorderRadius, greaterThan(0));
      });
    });

    group('font sizes', () {
      test('main window font sizes are positive', () {
        expect(AppConstants.fontSizeSmall, greaterThan(0));
        expect(AppConstants.fontSizeMedium, greaterThan(0));
        expect(AppConstants.fontSizeLarge, greaterThan(0));
        expect(AppConstants.fontSizeXLarge, greaterThan(0));
        expect(AppConstants.fontSizeLevel, greaterThan(0));
        expect(AppConstants.fontSizeExpProgress, greaterThan(0));
        expect(AppConstants.fontSizeButton, greaterThan(0));
      });

      test('dialog font sizes are positive', () {
        expect(AppConstants.fontSizeDialogTitle, greaterThan(0));
        expect(AppConstants.fontSizeDialogContent, greaterThan(0));
        expect(AppConstants.fontSizeDialogHint, greaterThan(0));
        expect(AppConstants.fontSizeDialogButton, greaterThan(0));
      });

      test('font sizes follow hierarchy', () {
        expect(AppConstants.fontSizeSmall, lessThan(AppConstants.fontSizeMedium));
        expect(AppConstants.fontSizeMedium, lessThan(AppConstants.fontSizeLarge));
        expect(AppConstants.fontSizeLarge, lessThan(AppConstants.fontSizeXLarge));
      });
    });

    group('animation durations', () {
      test('mouse click blink duration is positive', () {
        expect(AppConstants.mouseClickBlinkDurationMs, greaterThan(0));
      });
    });

    group('colors', () {
      test('transparent color is transparent', () {
        expect(AppConstants.transparentColor, Colors.transparent);
      });

      test('pomodoro colors are defined', () {
        expect(AppConstants.pomodoroFocusColor, isNotNull);
        expect(AppConstants.pomodoroRelaxColor, isNotNull);
      });
    });

    group('event channels', () {
      test('channel names are not empty', () {
        expect(AppConstants.keyEventsChannel, isNotEmpty);
        expect(AppConstants.mouseEventsChannel, isNotEmpty);
        expect(AppConstants.mouseControlChannel, isNotEmpty);
        expect(AppConstants.accessibilityChannel, isNotEmpty);
        expect(AppConstants.systemInfoChannel, isNotEmpty);
      });

      test('channel names follow convention', () {
        expect(AppConstants.keyEventsChannel, contains('cyber_cultivation'));
        expect(AppConstants.mouseEventsChannel, contains('cyber_cultivation'));
      });
    });

    group('UI strings', () {
      test('default strings are not empty', () {
        expect(AppConstants.defaultKeyText, isNotEmpty);
        expect(AppConstants.exitGameText, isNotEmpty);
        expect(AppConstants.pomodoroDialogTitle, isNotEmpty);
        expect(AppConstants.pomodoroStartButtonText, isNotEmpty);
        expect(AppConstants.cancelButtonText, isNotEmpty);
      });
    });
  });
}
