class SudokuSolver {
  const SudokuSolver();

  static const int gridSize = 81;
  static const int boardSize = 9;
  static const int boxSize = 3;

  bool isValidPuzzle(List<int> grid) {
    _validateGridShape(grid);

    for (final value in grid) {
      if (value < 0 || value > 9) {
        return false;
      }
    }

    for (var index = 0; index < grid.length; index++) {
      final value = grid[index];
      if (value == 0) {
        continue;
      }

      final row = index ~/ boardSize;
      final column = index % boardSize;

      if (!_canPlace(grid, row, column, value, skipIndex: index)) {
        return false;
      }
    }

    return true;
  }

  List<int>? solve(List<int> grid) {
    if (!isValidPuzzle(grid)) {
      return null;
    }

    final board = List<int>.from(grid);
    return _solveBoard(board) ? board : null;
  }

  int countSolutions(List<int> grid, {int limit = 2}) {
    if (limit < 1) {
      throw ArgumentError.value(limit, 'limit', 'Limit en az 1 olmalı.');
    }

    if (!isValidPuzzle(grid)) {
      return 0;
    }

    final board = List<int>.from(grid);
    return _countSolutions(board, limit);
  }

  bool hasUniqueSolution(List<int> grid) {
    return countSolutions(grid) == 1;
  }

  void _validateGridShape(List<int> grid) {
    if (grid.length != gridSize) {
      throw ArgumentError.value(
        grid.length,
        'grid.length',
        'Sudoku gridi tam olarak 81 elemanlı olmalı.',
      );
    }
  }

  bool _solveBoard(List<int> board) {
    final emptyIndex = _findBestEmptyCell(board);
    if (emptyIndex == null) {
      return true;
    }

    final row = emptyIndex ~/ boardSize;
    final column = emptyIndex % boardSize;

    for (var value = 1; value <= 9; value++) {
      if (_canPlace(board, row, column, value)) {
        board[emptyIndex] = value;

        if (_solveBoard(board)) {
          return true;
        }

        board[emptyIndex] = 0;
      }
    }

    return false;
  }

  int _countSolutions(List<int> board, int limit) {
    final emptyIndex = _findBestEmptyCell(board);
    if (emptyIndex == null) {
      return 1;
    }

    final row = emptyIndex ~/ boardSize;
    final column = emptyIndex % boardSize;
    var count = 0;

    for (var value = 1; value <= 9; value++) {
      if (_canPlace(board, row, column, value)) {
        board[emptyIndex] = value;
        count += _countSolutions(board, limit - count);
        board[emptyIndex] = 0;

        if (count >= limit) {
          return count;
        }
      }
    }

    return count;
  }

  int? _findBestEmptyCell(List<int> board) {
    int? bestIndex;
    var bestCandidateCount = 10;

    for (var index = 0; index < board.length; index++) {
      if (board[index] != 0) {
        continue;
      }

      final row = index ~/ boardSize;
      final column = index % boardSize;
      var candidateCount = 0;

      for (var value = 1; value <= 9; value++) {
        if (_canPlace(board, row, column, value)) {
          candidateCount++;
        }
      }

      if (candidateCount < bestCandidateCount) {
        bestCandidateCount = candidateCount;
        bestIndex = index;
      }

      if (candidateCount == 0) {
        return index;
      }
    }

    return bestIndex;
  }

  bool _canPlace(
    List<int> board,
    int row,
    int column,
    int value, {
    int? skipIndex,
  }) {
    for (var currentColumn = 0; currentColumn < boardSize; currentColumn++) {
      final index = row * boardSize + currentColumn;
      if (index != skipIndex && board[index] == value) {
        return false;
      }
    }

    for (var currentRow = 0; currentRow < boardSize; currentRow++) {
      final index = currentRow * boardSize + column;
      if (index != skipIndex && board[index] == value) {
        return false;
      }
    }

    final boxStartRow = (row ~/ boxSize) * boxSize;
    final boxStartColumn = (column ~/ boxSize) * boxSize;

    for (var rowOffset = 0; rowOffset < boxSize; rowOffset++) {
      for (var columnOffset = 0; columnOffset < boxSize; columnOffset++) {
        final index =
            (boxStartRow + rowOffset) * boardSize +
            boxStartColumn +
            columnOffset;

        if (index != skipIndex && board[index] == value) {
          return false;
        }
      }
    }

    return true;
  }
}
