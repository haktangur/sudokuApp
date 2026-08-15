import 'dart:math';

import 'sudoku_difficulty_analyzer.dart';
import 'sudoku_solver.dart';

class SudokuGenerator {
  SudokuGenerator({
    SudokuSolver solver = const SudokuSolver(),
    SudokuDifficultyAnalyzer? difficultyAnalyzer,
    Random? random,
    this.maxAttempts = 80,
  }) : _solver = solver,
       _difficultyAnalyzer =
           difficultyAnalyzer ?? SudokuDifficultyAnalyzer(solver: solver),
       _random = random ?? Random();

  static const Map<String, SudokuDifficultyTarget> difficultyTargets = {
    'Çok Kolay': SudokuDifficultyTarget(minEmptyCells: 35, maxEmptyCells: 40),
    'Kolay': SudokuDifficultyTarget(minEmptyCells: 41, maxEmptyCells: 45),
    'Orta': SudokuDifficultyTarget(minEmptyCells: 46, maxEmptyCells: 50),
    'Zor': SudokuDifficultyTarget(minEmptyCells: 51, maxEmptyCells: 55),
    'Uzman': SudokuDifficultyTarget(minEmptyCells: 56, maxEmptyCells: 60),
  };

  final SudokuSolver _solver;
  final SudokuDifficultyAnalyzer _difficultyAnalyzer;
  final Random _random;
  final int maxAttempts;
  final Set<String> _generatedFingerprints = <String>{};

  List<int> generatePuzzle(String difficulty) {
    final target = difficultyTargets[difficulty];
    if (target == null) {
      throw ArgumentError.value(
        difficulty,
        'difficulty',
        'Desteklenmeyen zorluk seviyesi.',
      );
    }

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final List<int> puzzle;
      try {
        final solution = generateCompletedGrid();
        puzzle = _createUniquePuzzle(solution, target);
      } on SudokuGenerationException {
        continue;
      }

      final analysis = _difficultyAnalyzer.analyze(puzzle);
      if (!analysis.isSolvable ||
          !analysis.isUnique ||
          analysis.difficulty != difficulty) {
        continue;
      }

      final fingerprint = createFingerprint(puzzle);

      if (_generatedFingerprints.add(fingerprint)) {
        return puzzle;
      }
    }

    throw SudokuGenerationException(
      'İstenen zorlukta benzersiz Sudoku puzzle üretilemedi. Maksimum deneme sayısı: $maxAttempts.',
    );
  }

  List<int> generateCompletedGrid() {
    final grid = List<int>.filled(SudokuSolver.gridSize, 0);
    final solved = _fillGrid(grid);

    if (!solved) {
      throw const SudokuGenerationException(
        'Tamamlanmış Sudoku gridi üretilemedi.',
      );
    }

    return grid;
  }

  String createFingerprint(List<int> grid) {
    if (grid.length != SudokuSolver.gridSize) {
      throw ArgumentError.value(
        grid.length,
        'grid.length',
        'Sudoku gridi tam olarak 81 elemanlı olmalı.',
      );
    }

    return grid.join();
  }

  List<int> _createUniquePuzzle(
    List<int> solution,
    SudokuDifficultyTarget target,
  ) {
    final puzzle = List<int>.from(solution);
    final positions = List<int>.generate(
      SudokuSolver.gridSize,
      (index) => index,
    )..shuffle(_random);
    final targetEmptyCells = target.randomValue(_random);
    var emptyCells = 0;

    for (final position in positions) {
      if (emptyCells >= targetEmptyCells) {
        break;
      }

      final removedValue = puzzle[position];
      puzzle[position] = 0;

      if (_solver.countSolutions(puzzle) == 1) {
        emptyCells++;
      } else {
        puzzle[position] = removedValue;
      }
    }

    if (emptyCells < target.minEmptyCells) {
      throw SudokuGenerationException(
        'Hedef boş hücre aralığına ulaşılamadı: $emptyCells/${target.minEmptyCells}.',
      );
    }

    return puzzle;
  }

  bool _fillGrid(List<int> grid) {
    final index = grid.indexOf(0);
    if (index == -1) {
      return true;
    }

    final row = index ~/ SudokuSolver.boardSize;
    final column = index % SudokuSolver.boardSize;
    final values = List<int>.generate(
      SudokuSolver.boardSize,
      (index) => index + 1,
    )..shuffle(_random);

    for (final value in values) {
      if (_canPlace(grid, row, column, value)) {
        grid[index] = value;

        if (_fillGrid(grid)) {
          return true;
        }

        grid[index] = 0;
      }
    }

    return false;
  }

  bool _canPlace(List<int> grid, int row, int column, int value) {
    for (
      var currentColumn = 0;
      currentColumn < SudokuSolver.boardSize;
      currentColumn++
    ) {
      if (grid[row * SudokuSolver.boardSize + currentColumn] == value) {
        return false;
      }
    }

    for (
      var currentRow = 0;
      currentRow < SudokuSolver.boardSize;
      currentRow++
    ) {
      if (grid[currentRow * SudokuSolver.boardSize + column] == value) {
        return false;
      }
    }

    final boxStartRow = (row ~/ SudokuSolver.boxSize) * SudokuSolver.boxSize;
    final boxStartColumn =
        (column ~/ SudokuSolver.boxSize) * SudokuSolver.boxSize;

    for (var rowOffset = 0; rowOffset < SudokuSolver.boxSize; rowOffset++) {
      for (
        var columnOffset = 0;
        columnOffset < SudokuSolver.boxSize;
        columnOffset++
      ) {
        final index =
            (boxStartRow + rowOffset) * SudokuSolver.boardSize +
            boxStartColumn +
            columnOffset;

        if (grid[index] == value) {
          return false;
        }
      }
    }

    return true;
  }
}

class SudokuDifficultyTarget {
  const SudokuDifficultyTarget({
    required this.minEmptyCells,
    required this.maxEmptyCells,
  });

  final int minEmptyCells;
  final int maxEmptyCells;

  int randomValue(Random random) {
    return minEmptyCells + random.nextInt(maxEmptyCells - minEmptyCells + 1);
  }
}

class SudokuGenerationException implements Exception {
  const SudokuGenerationException(this.message);

  final String message;

  @override
  String toString() => 'SudokuGenerationException: $message';
}
