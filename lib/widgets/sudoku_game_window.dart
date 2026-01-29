import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants.dart';
import '../l10n/app_localizations.dart';
import 'base_game_window.dart';

/// Difficulty levels for Sudoku
enum SudokuDifficulty { easy, medium, hard }

/// State of the sudoku game
enum SudokuGameState { selectDifficulty, playing, completed, failed }

/// Sudoku game widget
class SudokuGameWindow extends StatefulWidget {
  final AppThemeColors themeColors;
  final void Function(int expGained) onExpGained;

  const SudokuGameWindow({
    super.key,
    required this.themeColors,
    required this.onExpGained,
  });

  @override
  State<SudokuGameWindow> createState() => _SudokuGameWindowState();
}

class _SudokuGameWindowState extends State<SudokuGameWindow>
    with GameKeyboardMixin {
  // Game state
  SudokuGameState _gameState = SudokuGameState.selectDifficulty;
  SudokuDifficulty _difficulty = SudokuDifficulty.easy;

  // Puzzle data
  List<List<int>> _solution = [];
  List<List<int>> _puzzle = [];
  List<List<bool>> _fixed = [];
  List<List<bool>> _errors = [];

  // Selection
  int _selectedRow = -1;
  int _selectedCol = -1;

  // Game stats
  int _mistakes = 0;
  int _expGained = 0;
  int _elapsedSeconds = 0;
  Timer? _timer;

  // Focus node for keyboard input
  final FocusNode _focusNode = FocusNode();
  final Random _random = Random();

  AppThemeColors get _colors => widget.themeColors;

  @override
  void dispose() {
    _timer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _startGame(SudokuDifficulty difficulty) {
    setState(() {
      _difficulty = difficulty;
      _gameState = SudokuGameState.playing;
      _mistakes = 0;
      _expGained = 0;
      _elapsedSeconds = 0;
      _selectedRow = -1;
      _selectedCol = -1;
      _generatePuzzle();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_gameState == SudokuGameState.playing) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  void _generatePuzzle() {
    // Generate a complete valid solution
    _solution = List.generate(
      SudokuConstants.gridSize,
      (_) => List.filled(SudokuConstants.gridSize, 0),
    );
    _fillGrid(_solution);

    // Copy solution to puzzle
    _puzzle = List.generate(
      SudokuConstants.gridSize,
      (i) => List.from(_solution[i]),
    );

    // Initialize fixed and errors matrices
    _fixed = List.generate(
      SudokuConstants.gridSize,
      (_) => List.filled(SudokuConstants.gridSize, true),
    );
    _errors = List.generate(
      SudokuConstants.gridSize,
      (_) => List.filled(SudokuConstants.gridSize, false),
    );

    // Remove cells based on difficulty
    final cellsToRemove = switch (_difficulty) {
      SudokuDifficulty.easy => SudokuConstants.easyCellsToRemove,
      SudokuDifficulty.medium => SudokuConstants.mediumCellsToRemove,
      SudokuDifficulty.hard => SudokuConstants.hardCellsToRemove,
    };

    final cells = <(int, int)>[];
    for (int r = 0; r < SudokuConstants.gridSize; r++) {
      for (int c = 0; c < SudokuConstants.gridSize; c++) {
        cells.add((r, c));
      }
    }
    cells.shuffle(_random);

    for (int i = 0; i < cellsToRemove && i < cells.length; i++) {
      final (r, c) = cells[i];
      _puzzle[r][c] = 0;
      _fixed[r][c] = false;
    }
  }

  bool _fillGrid(List<List<int>> grid) {
    for (int row = 0; row < SudokuConstants.gridSize; row++) {
      for (int col = 0; col < SudokuConstants.gridSize; col++) {
        if (grid[row][col] == 0) {
          final numbers = List.generate(9, (i) => i + 1)..shuffle(_random);
          for (final num in numbers) {
            if (_isValidPlacement(grid, row, col, num)) {
              grid[row][col] = num;
              if (_fillGrid(grid)) {
                return true;
              }
              grid[row][col] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  bool _isValidPlacement(List<List<int>> grid, int row, int col, int num) {
    // Check row
    for (int c = 0; c < SudokuConstants.gridSize; c++) {
      if (grid[row][c] == num) return false;
    }

    // Check column
    for (int r = 0; r < SudokuConstants.gridSize; r++) {
      if (grid[r][col] == num) return false;
    }

    // Check 3x3 box
    final boxRow = (row ~/ SudokuConstants.boxSize) * SudokuConstants.boxSize;
    final boxCol = (col ~/ SudokuConstants.boxSize) * SudokuConstants.boxSize;
    for (int r = boxRow; r < boxRow + SudokuConstants.boxSize; r++) {
      for (int c = boxCol; c < boxCol + SudokuConstants.boxSize; c++) {
        if (grid[r][c] == num) return false;
      }
    }

    return true;
  }

  void _selectCell(int row, int col) {
    if (_gameState != SudokuGameState.playing) return;

    setState(() {
      if (_selectedRow == row && _selectedCol == col) {
        _selectedRow = -1;
        _selectedCol = -1;
      } else {
        _selectedRow = row;
        _selectedCol = col;
      }
    });
  }

  void _inputNumber(int number) {
    if (_gameState != SudokuGameState.playing) return;
    if (_selectedRow < 0 || _selectedCol < 0) return;
    if (_fixed[_selectedRow][_selectedCol]) return;

    setState(() {
      if (number == 0) {
        // Clear cell
        _puzzle[_selectedRow][_selectedCol] = 0;
        _errors[_selectedRow][_selectedCol] = false;
      } else {
        _puzzle[_selectedRow][_selectedCol] = number;

        // Check if correct
        if (number != _solution[_selectedRow][_selectedCol]) {
          _errors[_selectedRow][_selectedCol] = true;
          _mistakes++;

          if (_mistakes >= SudokuConstants.maxMistakes) {
            _endGame(completed: false);
          }
        } else {
          _errors[_selectedRow][_selectedCol] = false;

          // Check if puzzle is complete
          if (_isPuzzleComplete()) {
            _endGame(completed: true);
          }
        }
      }
    });
  }

  bool _isPuzzleComplete() {
    for (int r = 0; r < SudokuConstants.gridSize; r++) {
      for (int c = 0; c < SudokuConstants.gridSize; c++) {
        if (_puzzle[r][c] != _solution[r][c]) {
          return false;
        }
      }
    }
    return true;
  }

  void _endGame({required bool completed}) {
    _timer?.cancel();

    if (completed) {
      _expGained =
          SudokuConstants.expPerCompletion +
          switch (_difficulty) {
            SudokuDifficulty.easy => SudokuConstants.expBonusEasy,
            SudokuDifficulty.medium => SudokuConstants.expBonusMedium,
            SudokuDifficulty.hard => SudokuConstants.expBonusHard,
          };
      widget.onExpGained(_expGained);
    }

    setState(() {
      _gameState = completed
          ? SudokuGameState.completed
          : SudokuGameState.failed;
    });
  }

  void _handleKeyEvent(KeyEvent event) {
    if (handleCommonKeyEvent(event)) return;
    if (event is! KeyDownEvent) return;

    if (_gameState == SudokuGameState.playing) {
      // Number keys 1-9
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.digit1 ||
          key == LogicalKeyboardKey.numpad1) {
        _inputNumber(1);
      } else if (key == LogicalKeyboardKey.digit2 ||
          key == LogicalKeyboardKey.numpad2) {
        _inputNumber(2);
      } else if (key == LogicalKeyboardKey.digit3 ||
          key == LogicalKeyboardKey.numpad3) {
        _inputNumber(3);
      } else if (key == LogicalKeyboardKey.digit4 ||
          key == LogicalKeyboardKey.numpad4) {
        _inputNumber(4);
      } else if (key == LogicalKeyboardKey.digit5 ||
          key == LogicalKeyboardKey.numpad5) {
        _inputNumber(5);
      } else if (key == LogicalKeyboardKey.digit6 ||
          key == LogicalKeyboardKey.numpad6) {
        _inputNumber(6);
      } else if (key == LogicalKeyboardKey.digit7 ||
          key == LogicalKeyboardKey.numpad7) {
        _inputNumber(7);
      } else if (key == LogicalKeyboardKey.digit8 ||
          key == LogicalKeyboardKey.numpad8) {
        _inputNumber(8);
      } else if (key == LogicalKeyboardKey.digit9 ||
          key == LogicalKeyboardKey.numpad9) {
        _inputNumber(9);
      } else if (key == LogicalKeyboardKey.digit0 ||
          key == LogicalKeyboardKey.numpad0 ||
          key == LogicalKeyboardKey.backspace ||
          key == LogicalKeyboardKey.delete) {
        _inputNumber(0);
      }

      // Arrow keys for navigation
      if (key == LogicalKeyboardKey.arrowUp && _selectedRow > 0) {
        setState(() => _selectedRow--);
      } else if (key == LogicalKeyboardKey.arrowDown &&
          _selectedRow < SudokuConstants.gridSize - 1) {
        setState(() => _selectedRow++);
      } else if (key == LogicalKeyboardKey.arrowLeft && _selectedCol > 0) {
        setState(() => _selectedCol--);
      } else if (key == LogicalKeyboardKey.arrowRight &&
          _selectedCol < SudokuConstants.gridSize - 1) {
        setState(() => _selectedCol++);
      }
    }
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(
        SudokuConstants.gameDialogInsetPadding,
      ),
      child: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Container(
          width: size.width > SudokuConstants.gameDialogMaxWidth
              ? SudokuConstants.gameDialogMaxWidth
              : size.width * SudokuConstants.gameDialogWidthRatio,
          height: size.height > SudokuConstants.gameDialogMaxHeight
              ? SudokuConstants.gameDialogMaxHeight
              : size.height * SudokuConstants.gameDialogHeightRatio,
          decoration: BoxDecoration(
            color: _colors.dialogBackground,
            borderRadius: BorderRadius.circular(
              SudokuConstants.gameDialogBorderRadius,
            ),
            border: Border.all(color: _colors.border.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: _colors.brightness == Brightness.dark
                    ? Colors.black.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.2),
                blurRadius: SudokuConstants.gameDialogShadowBlur,
                spreadRadius: SudokuConstants.gameDialogShadowSpread,
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(l10n),
              Expanded(child: _buildContent(l10n)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SudokuConstants.gameHeaderPaddingH,
        vertical: SudokuConstants.gameHeaderPaddingV,
      ),
      decoration: BoxDecoration(
        color: _colors.overlayLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(SudokuConstants.gameDialogBorderRadius),
          topRight: Radius.circular(SudokuConstants.gameDialogBorderRadius),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.grid_3x3,
                color: _colors.accent,
                size: SudokuConstants.gameHeaderIconSize,
              ),
              const SizedBox(width: SudokuConstants.gameHeaderIconSpacing),
              Text(
                l10n.sudokuTitle,
                style: TextStyle(
                  color: _colors.primaryText,
                  fontSize: SudokuConstants.gameHeaderFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (_gameState == SudokuGameState.playing) ...[
                _buildInfoChip(
                  l10n.sudokuMistakes(_mistakes, SudokuConstants.maxMistakes),
                  _mistakes > 0 ? _colors.error : _colors.secondaryText,
                ),
                const SizedBox(width: SudokuConstants.headerButtonSpacing),
                _buildInfoChip(
                  l10n.sudokuTime(_formatTime(_elapsedSeconds)),
                  _colors.secondaryText,
                ),
                const SizedBox(width: SudokuConstants.headerButtonSpacing),
              ],
              IconButton(
                icon: Icon(Icons.close, color: _colors.secondaryText),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SudokuConstants.infoPaddingH,
        vertical: SudokuConstants.infoPaddingV,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(SudokuConstants.infoBorderRadius),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: SudokuConstants.infoFontSize,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    return switch (_gameState) {
      SudokuGameState.selectDifficulty => _buildDifficultySelector(l10n),
      SudokuGameState.playing => _buildGameArea(l10n),
      SudokuGameState.completed => _buildCompletedOverlay(l10n),
      SudokuGameState.failed => _buildFailedOverlay(l10n),
    };
  }

  Widget _buildDifficultySelector(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.grid_3x3, color: _colors.accent, size: 48),
          const SizedBox(height: 16),
          Text(
            l10n.sudokuTitle,
            style: TextStyle(
              color: _colors.primaryText,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.sudokuSelectNumber,
            style: TextStyle(color: _colors.secondaryText, fontSize: 12),
          ),
          const SizedBox(height: 32),
          _buildDifficultyButton(l10n.sudokuEasy, SudokuDifficulty.easy),
          const SizedBox(height: 12),
          _buildDifficultyButton(l10n.sudokuMedium, SudokuDifficulty.medium),
          const SizedBox(height: 12),
          _buildDifficultyButton(l10n.sudokuHard, SudokuDifficulty.hard),
        ],
      ),
    );
  }

  Widget _buildDifficultyButton(String text, SudokuDifficulty difficulty) {
    final expBonus = switch (difficulty) {
      SudokuDifficulty.easy => SudokuConstants.expBonusEasy,
      SudokuDifficulty.medium => SudokuConstants.expBonusMedium,
      SudokuDifficulty.hard => SudokuConstants.expBonusHard,
    };
    final totalExp = SudokuConstants.expPerCompletion + expBonus;

    return SizedBox(
      width: 200,
      child: ElevatedButton(
        onPressed: () => _startGame(difficulty),
        style: ElevatedButton.styleFrom(
          backgroundColor: _colors.accent,
          foregroundColor: _colors.brightness == Brightness.dark
              ? Colors.black
              : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          children: [
            Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '+$totalExp EXP',
              style: TextStyle(
                fontSize: 11,
                color:
                    (_colors.brightness == Brightness.dark
                            ? Colors.black
                            : Colors.white)
                        .withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameArea(AppLocalizations l10n) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildGrid(),
                  const SizedBox(height: 16),
                  _buildNumberPad(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGrid() {
    return Container(
      padding: const EdgeInsets.all(SudokuConstants.gridPadding),
      decoration: BoxDecoration(
        color: _colors.brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: SudokuConstants.boxLineColor,
          width: SudokuConstants.gridBorderWidth,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(SudokuConstants.gridSize, (row) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(SudokuConstants.gridSize, (col) {
              return _buildCell(row, col);
            }),
          );
        }),
      ),
    );
  }

  Widget _buildCell(int row, int col) {
    final value = _puzzle[row][col];
    final isFixed = _fixed[row][col];
    final isError = _errors[row][col];
    final isSelected = row == _selectedRow && col == _selectedCol;

    // Highlight cells in same row, column, or box
    final isSameRow = row == _selectedRow;
    final isSameCol = col == _selectedCol;
    final isSameBox =
        _selectedRow >= 0 &&
        _selectedCol >= 0 &&
        (row ~/ SudokuConstants.boxSize ==
            _selectedRow ~/ SudokuConstants.boxSize) &&
        (col ~/ SudokuConstants.boxSize ==
            _selectedCol ~/ SudokuConstants.boxSize);
    final isHighlighted = !isSelected && (isSameRow || isSameCol || isSameBox);

    // Highlight cells with same number
    final selectedValue = _selectedRow >= 0 && _selectedCol >= 0
        ? _puzzle[_selectedRow][_selectedCol]
        : 0;
    final isSameNumber = !isSelected && value != 0 && value == selectedValue;

    // Determine border widths
    final rightBorder =
        (col + 1) % SudokuConstants.boxSize == 0 &&
            col < SudokuConstants.gridSize - 1
        ? SudokuConstants.boxBorderWidth
        : SudokuConstants.cellBorderWidth;
    final bottomBorder =
        (row + 1) % SudokuConstants.boxSize == 0 &&
            row < SudokuConstants.gridSize - 1
        ? SudokuConstants.boxBorderWidth
        : SudokuConstants.cellBorderWidth;

    Color bgColor;
    if (isSelected) {
      bgColor = SudokuConstants.selectedCellColor;
    } else if (isSameNumber) {
      bgColor = SudokuConstants.sameNumberColor;
    } else if (isHighlighted) {
      bgColor = SudokuConstants.highlightColor;
    } else {
      bgColor = Colors.transparent;
    }

    Color textColor;
    if (isError) {
      textColor = SudokuConstants.errorNumberColor;
    } else if (isFixed) {
      textColor = _colors.brightness == Brightness.dark
          ? Colors.white
          : SudokuConstants.fixedNumberColor;
    } else {
      textColor = SudokuConstants.userNumberColor;
    }

    return GestureDetector(
      onTap: () => _selectCell(row, col),
      child: Container(
        width: SudokuConstants.cellSize,
        height: SudokuConstants.cellSize,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            right: BorderSide(
              color: rightBorder == SudokuConstants.boxBorderWidth
                  ? SudokuConstants.boxLineColor
                  : SudokuConstants.gridLineColor,
              width: rightBorder,
            ),
            bottom: BorderSide(
              color: bottomBorder == SudokuConstants.boxBorderWidth
                  ? SudokuConstants.boxLineColor
                  : SudokuConstants.gridLineColor,
              width: bottomBorder,
            ),
          ),
        ),
        child: Center(
          child: Text(
            value == 0 ? '' : value.toString(),
            style: TextStyle(
              color: textColor,
              fontSize: SudokuConstants.numberFontSize,
              fontWeight: isFixed ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SudokuConstants.numberPadPadding,
      ),
      child: Wrap(
        spacing: SudokuConstants.numberButtonSpacing,
        runSpacing: SudokuConstants.numberButtonSpacing,
        alignment: WrapAlignment.center,
        children: [
          for (int i = 1; i <= 9; i++) _buildNumberButton(i),
          _buildNumberButton(0, icon: Icons.backspace_outlined),
        ],
      ),
    );
  }

  Widget _buildNumberButton(int number, {IconData? icon}) {
    final isDisabled =
        _selectedRow < 0 ||
        _selectedCol < 0 ||
        _fixed[_selectedRow][_selectedCol];

    return SizedBox(
      width: SudokuConstants.numberButtonSize,
      height: SudokuConstants.numberButtonSize,
      child: ElevatedButton(
        onPressed: isDisabled ? null : () => _inputNumber(number),
        style: ElevatedButton.styleFrom(
          backgroundColor: _colors.accent.withValues(alpha: 0.2),
          foregroundColor: _colors.accent,
          disabledBackgroundColor: _colors.border.withValues(alpha: 0.1),
          disabledForegroundColor: _colors.secondaryText.withValues(alpha: 0.5),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: icon != null
            ? Icon(icon, size: 20)
            : Text(
                number.toString(),
                style: const TextStyle(
                  fontSize: SudokuConstants.numberFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildCompletedOverlay(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.celebration, color: _colors.accent, size: 64),
          const SizedBox(height: 16),
          Text(
            l10n.sudokuCompleted,
            style: TextStyle(
              color: _colors.accent,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.sudokuTime(_formatTime(_elapsedSeconds)),
            style: TextStyle(color: _colors.secondaryText, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.gameExpGained(_expGained),
            style: TextStyle(
              color: _colors.accent,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() {
              _gameState = SudokuGameState.selectDifficulty;
            }),
            icon: const Icon(Icons.replay),
            label: Text(l10n.sudokuNewGame),
            style: ElevatedButton.styleFrom(
              backgroundColor: _colors.accent,
              foregroundColor: _colors.brightness == Brightness.dark
                  ? Colors.black
                  : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedOverlay(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sentiment_dissatisfied, color: _colors.error, size: 64),
          const SizedBox(height: 16),
          Text(
            l10n.sudokuTooManyMistakes,
            style: TextStyle(
              color: _colors.error,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.sudokuTime(_formatTime(_elapsedSeconds)),
            style: TextStyle(color: _colors.secondaryText, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() {
              _gameState = SudokuGameState.selectDifficulty;
            }),
            icon: const Icon(Icons.replay),
            label: Text(l10n.sudokuNewGame),
            style: ElevatedButton.styleFrom(
              backgroundColor: _colors.accent,
              foregroundColor: _colors.brightness == Brightness.dark
                  ? Colors.black
                  : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
