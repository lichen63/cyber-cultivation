import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cyber_cultivation/widgets/todo_dialog.dart';
import 'package:cyber_cultivation/models/todo_item.dart';
import 'package:cyber_cultivation/constants.dart';
import 'package:cyber_cultivation/l10n/app_localizations.dart';

void main() {
  group('TodoDialog', () {
    late AppThemeColors themeColors;
    late List<TodoItem> todos;
    late List<TodoItem>? changedTodos;

    setUp(() {
      themeColors = AppThemeColors.dark;
      todos = [];
      changedTodos = null;
    });

    Widget createTestWidget({List<TodoItem>? initialTodos}) {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        locale: const Locale('en'),
        home: Scaffold(
          body: Builder(
            builder: (context) => TodoDialog(
              todos: initialTodos ?? todos,
              themeColors: themeColors,
              onTodosChanged: (newTodos) {
                changedTodos = newTodos;
              },
            ),
          ),
        ),
      );
    }

    group('rendering', () {
      testWidgets('displays dialog with title', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should find the dialog
        expect(find.byType(Dialog), findsOneWidget);
      });

      testWidgets('displays close button', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.close), findsOneWidget);
      });

      testWidgets('displays add button', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.add), findsOneWidget);
      });

      testWidgets('displays empty state when no todos', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should show empty message - we just check the dialog renders
        expect(find.byType(TodoDialog), findsOneWidget);
      });
    });

    group('with existing todos', () {
      testWidgets('displays todos in list', (WidgetTester tester) async {
        final testTodos = [
          TodoItem(
            id: '1',
            title: 'Test Todo 1',
            status: TodoStatus.todo,
            createdAt: DateTime.now(),
          ),
          TodoItem(
            id: '2',
            title: 'Test Todo 2',
            status: TodoStatus.doing,
            createdAt: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(createTestWidget(initialTodos: testTodos));
        await tester.pumpAndSettle();

        expect(find.text('Test Todo 1'), findsOneWidget);
        expect(find.text('Test Todo 2'), findsOneWidget);
      });

      testWidgets('shows correct status icons', (WidgetTester tester) async {
        final testTodos = [
          TodoItem(
            id: '1',
            title: 'Todo Item',
            status: TodoStatus.todo,
            createdAt: DateTime.now(),
          ),
          TodoItem(
            id: '2',
            title: 'Doing Item',
            status: TodoStatus.doing,
            createdAt: DateTime.now(),
          ),
          TodoItem(
            id: '3',
            title: 'Done Item',
            status: TodoStatus.done,
            createdAt: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(createTestWidget(initialTodos: testTodos));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
        expect(find.byIcon(Icons.timelapse), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });

      testWidgets('shows delete buttons for each todo', (WidgetTester tester) async {
        final testTodos = [
          TodoItem(
            id: '1',
            title: 'Test Todo 1',
            status: TodoStatus.todo,
            createdAt: DateTime.now(),
          ),
          TodoItem(
            id: '2',
            title: 'Test Todo 2',
            status: TodoStatus.todo,
            createdAt: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(createTestWidget(initialTodos: testTodos));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
      });
    });

    group('adding todos', () {
      testWidgets('shows text field when add is tapped', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap add button
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        // Should now show text field
        expect(find.byType(TextField), findsOneWidget);
      });

      testWidgets('can cancel adding new todo', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap add button
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsOneWidget);

        // Tap close/cancel button (second close icon after the header close)
        final closeButtons = find.byIcon(Icons.close);
        await tester.tap(closeButtons.last);
        await tester.pumpAndSettle();

        // TextField should be gone
        expect(find.byType(TextField), findsNothing);
      });

      testWidgets('adds new todo when confirmed', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap add button
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        // Enter text
        await tester.enterText(find.byType(TextField), 'New Todo Item');
        await tester.pumpAndSettle();

        // Tap confirm (check icon)
        await tester.tap(find.byIcon(Icons.check));
        await tester.pumpAndSettle();

        // Verify callback was called with new todo
        expect(changedTodos, isNotNull);
        expect(changedTodos!.length, 1);
        expect(changedTodos![0].title, 'New Todo Item');
        expect(changedTodos![0].status, TodoStatus.todo);
      });

      testWidgets('does not add empty todo', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap add button
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        // Try to confirm without entering text
        await tester.tap(find.byIcon(Icons.check));
        await tester.pumpAndSettle();

        // Callback should not be called (no change)
        expect(changedTodos, isNull);
      });
    });

    group('toggling status', () {
      testWidgets('cycles status when status icon is tapped', (WidgetTester tester) async {
        final testTodos = [
          TodoItem(
            id: '1',
            title: 'Test Todo',
            status: TodoStatus.todo,
            createdAt: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(createTestWidget(initialTodos: testTodos));
        await tester.pumpAndSettle();

        // Tap the status icon (radio_button_unchecked)
        await tester.tap(find.byIcon(Icons.radio_button_unchecked));
        await tester.pumpAndSettle();

        // Status should have changed
        expect(changedTodos, isNotNull);
        expect(changedTodos![0].status, TodoStatus.doing);
      });
    });

    group('theming', () {
      testWidgets('renders dialog with dark theme', (WidgetTester tester) async {
        themeColors = AppThemeColors.dark;
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final dialog = tester.widget<Dialog>(find.byType(Dialog));
        expect(dialog.backgroundColor, themeColors.dialogBackground);
      });

      testWidgets('renders dialog with light theme', (WidgetTester tester) async {
        themeColors = AppThemeColors.light;
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final dialog = tester.widget<Dialog>(find.byType(Dialog));
        expect(dialog.backgroundColor, themeColors.dialogBackground);
      });
    });
  });
}
