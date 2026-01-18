/// Test index file that exports all test groups
///
/// Run all tests with: flutter test
/// Run specific test file: flutter test test/models/game_data_test.dart
///
/// Test structure:
/// - test/models/ - Unit tests for data models
/// - test/services/ - Unit tests for services
/// - test/widgets/ - Widget tests for UI components
/// - test/integration/ - Integration tests for feature flows
/// - test/constants_test.dart - Tests for app constants
library;

import 'package:flutter_test/flutter_test.dart';

// Import all test files to ensure they're discoverable
import 'models/daily_stats_test.dart' as daily_stats_test;
import 'models/todo_item_test.dart' as todo_item_test;
import 'models/game_data_test.dart' as game_data_test;
import 'services/pomodoro_service_test.dart' as pomodoro_service_test;
import 'widgets/styled_button_test.dart' as styled_button_test;
import 'widgets/exp_display_test.dart' as exp_display_test;
import 'widgets/todo_dialog_test.dart' as todo_dialog_test;
import 'integration/game_flow_test.dart' as game_flow_test;
import 'constants_test.dart' as constants_test;

void main() {
  group('All Tests', () {
    group('Models', () {
      daily_stats_test.main();
      todo_item_test.main();
      game_data_test.main();
    });

    group('Services', () {
      pomodoro_service_test.main();
    });

    group('Widgets', () {
      styled_button_test.main();
      exp_display_test.main();
      todo_dialog_test.main();
    });

    group('Integration', () {
      game_flow_test.main();
    });

    group('Constants', () {
      constants_test.main();
    });
  });
}
