import 'package:flutter/material.dart';
import '../constants.dart';
import '../l10n/app_localizations.dart';
import '../models/todo_item.dart';

/// Dialog for managing todo list
class TodoDialog extends StatefulWidget {
  final List<TodoItem> todos;
  final AppThemeColors themeColors;
  final ValueChanged<List<TodoItem>> onTodosChanged;

  const TodoDialog({
    super.key,
    required this.todos,
    required this.themeColors,
    required this.onTodosChanged,
  });

  @override
  State<TodoDialog> createState() => _TodoDialogState();
}

class _TodoDialogState extends State<TodoDialog> {
  late List<TodoItem> _todos;
  final TextEditingController _newTodoController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _isAddingTodo = false;

  @override
  void initState() {
    super.initState();
    _todos = List.from(widget.todos);
  }

  @override
  void dispose() {
    _newTodoController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _addTodo() {
    final text = _newTodoController.text.trim();
    if (text.isEmpty) return;

    final newTodo = TodoItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: text,
      status: TodoStatus.todo,
      createdAt: DateTime.now(),
    );

    setState(() {
      _todos.insert(0, newTodo);
      _newTodoController.clear();
      _isAddingTodo = false;
    });
    widget.onTodosChanged(_todos);
  }

  void _toggleTodoStatus(int index) {
    setState(() {
      _todos[index] = _todos[index].cycleStatus();
    });
    widget.onTodosChanged(_todos);
  }

  void _deleteTodo(int index) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierColor: widget.themeColors.overlay,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: widget.themeColors.dialogBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            side: BorderSide(color: widget.themeColors.border, width: 2),
          ),
          title: Text(
            l10n.todoDeleteConfirmTitle,
            style: TextStyle(color: widget.themeColors.error),
          ),
          content: Text(
            l10n.todoDeleteConfirmContent,
            style: TextStyle(color: widget.themeColors.primaryText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.cancelButtonText,
                style: TextStyle(color: widget.themeColors.inactive),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _todos.removeAt(index);
                });
                widget.onTodosChanged(_todos);
              },
              child: Text(
                l10n.deleteButtonText,
                style: TextStyle(color: widget.themeColors.error),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getStatusText(TodoStatus status, AppLocalizations l10n) {
    return switch (status) {
      TodoStatus.todo => l10n.todoStatusTodo,
      TodoStatus.doing => l10n.todoStatusDoing,
      TodoStatus.done => l10n.todoStatusDone,
    };
  }

  Color _getStatusColor(TodoStatus status) {
    return switch (status) {
      TodoStatus.todo => widget.themeColors.inactive,
      TodoStatus.doing => widget.themeColors.accent,
      TodoStatus.done => AppConstants.pomodoroRelaxColor,
    };
  }

  IconData _getStatusIcon(TodoStatus status) {
    return switch (status) {
      TodoStatus.todo => Icons.radio_button_unchecked,
      TodoStatus.doing => Icons.timelapse,
      TodoStatus.done => Icons.check_circle,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeColors = widget.themeColors;

    return Dialog(
      backgroundColor: themeColors.dialogBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        side: BorderSide(color: themeColors.border, width: 2),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 500,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.todoTitle,
                    style: TextStyle(
                      fontSize: AppConstants.fontSizeDialogTitle,
                      fontWeight: FontWeight.bold,
                      color: themeColors.primaryText,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: themeColors.inactive),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Add Todo Section
              if (_isAddingTodo) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newTodoController,
                        focusNode: _inputFocusNode,
                        autofocus: true,
                        style: TextStyle(color: themeColors.primaryText),
                        decoration: InputDecoration(
                          hintText: l10n.todoNewPlaceholder,
                          hintStyle:
                              TextStyle(color: themeColors.secondaryText),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.smallBorderRadius,
                            ),
                            borderSide: BorderSide(color: themeColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.smallBorderRadius,
                            ),
                            borderSide: BorderSide(color: themeColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.smallBorderRadius,
                            ),
                            borderSide: BorderSide(color: themeColors.accent),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onSubmitted: (_) => _addTodo(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _addTodo,
                      icon: Icon(Icons.check, color: themeColors.accent),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isAddingTodo = false;
                          _newTodoController.clear();
                        });
                      },
                      icon: Icon(Icons.close, color: themeColors.inactive),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ] else ...[
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isAddingTodo = true;
                    });
                  },
                  icon: Icon(Icons.add, color: themeColors.accent),
                  label: Text(
                    l10n.todoAddNew,
                    style: TextStyle(color: themeColors.accent),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Todo List
              Flexible(
                child: _todos.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            l10n.todoEmpty,
                            style: TextStyle(color: themeColors.secondaryText),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _todos.length,
                        itemBuilder: (context, index) {
                          final todo = _todos[index];
                          final statusColor = _getStatusColor(todo.status);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Container(
                              decoration: BoxDecoration(
                                color: themeColors.overlayLight,
                                borderRadius: BorderRadius.circular(
                                  AppConstants.smallBorderRadius,
                                ),
                                border: Border.all(
                                  color: statusColor.withValues(alpha: 0.5),
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 0,
                                ),
                                leading: InkWell(
                                  onTap: () => _toggleTodoStatus(index),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(
                                      _getStatusIcon(todo.status),
                                      color: statusColor,
                                      size: 28,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  todo.title,
                                  style: TextStyle(
                                    color: todo.status == TodoStatus.done
                                        ? themeColors.secondaryText
                                        : themeColors.primaryText,
                                    decoration: todo.status == TodoStatus.done
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                subtitle: Text(
                                  _getStatusText(todo.status, l10n),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: AppConstants.fontSizeDialogHint,
                                  ),
                                ),
                                trailing: IconButton(
                                  onPressed: () => _deleteTodo(index),
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: themeColors.error.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
