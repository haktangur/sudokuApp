import 'sudoku_solver.dart';

enum SudokuTechnique {
  nakedSingle('Naked Single', 1, 1),
  hiddenSingle('Hidden Single', 2, 1),
  nakedPair('Naked Pair', 4, 2),
  nakedTriple('Naked Triple', 7, 3),
  pointingPair('Pointing Pair / Triple', 6, 3),
  boxLineReduction('Box-Line Reduction', 6, 3),
  search('Controlled Search', 12, 4);

  const SudokuTechnique(this.label, this.weight, this.level);

  final String label;
  final int weight;
  final int level;
}

class SudokuDifficultyAnalyzer {
  const SudokuDifficultyAnalyzer({SudokuSolver solver = const SudokuSolver()})
    : _solver = solver;

  static const List<String> difficulties = [
    'Çok Kolay',
    'Kolay',
    'Orta',
    'Zor',
    'Uzman',
  ];

  static const Map<SudokuTechnique, int> techniqueWeights = {
    SudokuTechnique.nakedSingle: 1,
    SudokuTechnique.hiddenSingle: 2,
    SudokuTechnique.nakedPair: 4,
    SudokuTechnique.nakedTriple: 7,
    SudokuTechnique.pointingPair: 6,
    SudokuTechnique.boxLineReduction: 6,
    SudokuTechnique.search: 12,
  };

  final SudokuSolver _solver;

  DifficultyAnalysis analyze(List<int> puzzle) {
    _validateGridShape(puzzle);

    final valueRangeIsValid = puzzle.every((value) => value >= 0 && value <= 9);
    if (!valueRangeIsValid || !_solver.isValidPuzzle(puzzle)) {
      return DifficultyAnalysis.invalid();
    }

    final solutionCount = _solver.countSolutions(puzzle);
    if (solutionCount == 0) {
      return DifficultyAnalysis.invalid();
    }

    final isUnique = solutionCount == 1;
    if (!isUnique) {
      return DifficultyAnalysis(
        isSolvable: true,
        isUnique: false,
        score: 0,
        difficulty: 'Geçersiz',
        usedTechniques: const <SudokuTechnique>[],
        maxTechnique: null,
        logicalSteps: const <LogicalSolveStep>[],
      );
    }

    final logicalResult = _solveLogically(puzzle);
    final steps = List<LogicalSolveStep>.from(logicalResult.steps);

    if (!logicalResult.isSolved) {
      steps.add(
        const LogicalSolveStep(
          technique: SudokuTechnique.search,
          description:
              'Mantıksal teknikler ilerleyemedi; çözüm solver ile doğrulandı.',
        ),
      );
    }

    final usedTechniques = _collectUsedTechniques(steps);
    final maxTechnique = _maxTechnique(usedTechniques);
    final score = _calculateScore(steps, maxTechnique);
    final difficulty = _classify(
      puzzle: puzzle,
      score: score,
      maxTechnique: maxTechnique,
      requiresSearch: !logicalResult.isSolved,
    );

    return DifficultyAnalysis(
      isSolvable: true,
      isUnique: true,
      score: score,
      difficulty: difficulty,
      usedTechniques: usedTechniques,
      maxTechnique: maxTechnique,
      logicalSteps: steps,
    );
  }

  LogicalSolveResult _solveLogically(List<int> puzzle) {
    final board = List<int>.from(puzzle);
    var candidates = _buildCandidates(board);
    final steps = <LogicalSolveStep>[];

    while (!board.every((value) => value != 0)) {
      final nakedSingle = _findNakedSingle(board, candidates);
      if (nakedSingle != null) {
        _placeValue(board, nakedSingle.index, nakedSingle.value);
        steps.add(
          LogicalSolveStep(
            technique: SudokuTechnique.nakedSingle,
            cellIndex: nakedSingle.index,
            value: nakedSingle.value,
            description: 'Tek aday değeri yerleştirildi.',
          ),
        );
        candidates = _buildCandidates(board);
        continue;
      }

      final hiddenSingle = _findHiddenSingle(board, candidates);
      if (hiddenSingle != null) {
        _placeValue(board, hiddenSingle.index, hiddenSingle.value);
        steps.add(
          LogicalSolveStep(
            technique: SudokuTechnique.hiddenSingle,
            cellIndex: hiddenSingle.index,
            value: hiddenSingle.value,
            description: 'Unit içinde tek mümkün konum bulundu.',
          ),
        );
        candidates = _buildCandidates(board);
        continue;
      }

      final nakedPairRemoved = _applyNakedSubset(
        board,
        candidates,
        subsetSize: 2,
      );
      if (nakedPairRemoved > 0) {
        steps.add(
          LogicalSolveStep(
            technique: SudokuTechnique.nakedPair,
            removedCandidates: nakedPairRemoved,
            description: 'Naked Pair ile adaylar elendi.',
          ),
        );
        continue;
      }

      final nakedTripleRemoved = _applyNakedSubset(
        board,
        candidates,
        subsetSize: 3,
      );
      if (nakedTripleRemoved > 0) {
        steps.add(
          LogicalSolveStep(
            technique: SudokuTechnique.nakedTriple,
            removedCandidates: nakedTripleRemoved,
            description: 'Naked Triple ile adaylar elendi.',
          ),
        );
        continue;
      }

      final pointingRemoved = _applyPointingReduction(board, candidates);
      if (pointingRemoved > 0) {
        steps.add(
          LogicalSolveStep(
            technique: SudokuTechnique.pointingPair,
            removedCandidates: pointingRemoved,
            description: 'Pointing tekniği ile adaylar elendi.',
          ),
        );
        continue;
      }

      final boxLineRemoved = _applyBoxLineReduction(board, candidates);
      if (boxLineRemoved > 0) {
        steps.add(
          LogicalSolveStep(
            technique: SudokuTechnique.boxLineReduction,
            removedCandidates: boxLineRemoved,
            description: 'Box-Line Reduction ile adaylar elendi.',
          ),
        );
        continue;
      }

      break;
    }

    return LogicalSolveResult(
      isSolved: board.every((value) => value != 0),
      steps: steps,
    );
  }

  List<Set<int>> _buildCandidates(List<int> board) {
    return List<Set<int>>.generate(SudokuSolver.gridSize, (index) {
      if (board[index] != 0) {
        return <int>{};
      }

      final row = index ~/ SudokuSolver.boardSize;
      final column = index % SudokuSolver.boardSize;
      final values = <int>{};

      for (var value = 1; value <= SudokuSolver.boardSize; value++) {
        if (_canPlace(board, row, column, value)) {
          values.add(value);
        }
      }

      return values;
    });
  }

  _Placement? _findNakedSingle(List<int> board, List<Set<int>> candidates) {
    for (var index = 0; index < board.length; index++) {
      if (board[index] == 0 && candidates[index].length == 1) {
        return _Placement(index, candidates[index].first);
      }
    }

    return null;
  }

  _Placement? _findHiddenSingle(List<int> board, List<Set<int>> candidates) {
    for (final unit in _units) {
      for (var value = 1; value <= SudokuSolver.boardSize; value++) {
        final possibleIndexes = unit
            .where(
              (index) => board[index] == 0 && candidates[index].contains(value),
            )
            .toList();

        if (possibleIndexes.length == 1) {
          return _Placement(possibleIndexes.first, value);
        }
      }
    }

    return null;
  }

  int _applyNakedSubset(
    List<int> board,
    List<Set<int>> candidates, {
    required int subsetSize,
  }) {
    var removed = 0;

    for (final unit in _units) {
      final indexes = unit
          .where(
            (index) =>
                board[index] == 0 &&
                candidates[index].length >= 2 &&
                candidates[index].length <= subsetSize,
          )
          .toList();

      final combinations = _combinations(indexes, subsetSize);
      for (final combination in combinations) {
        final combinedCandidates = <int>{};
        for (final index in combination) {
          combinedCandidates.addAll(candidates[index]);
        }

        if (combinedCandidates.length != subsetSize) {
          continue;
        }

        for (final index in unit) {
          if (combination.contains(index) || board[index] != 0) {
            continue;
          }

          final before = candidates[index].length;
          candidates[index].removeAll(combinedCandidates);
          removed += before - candidates[index].length;
        }

        if (removed > 0) {
          return removed;
        }
      }
    }

    return removed;
  }

  int _applyPointingReduction(List<int> board, List<Set<int>> candidates) {
    var removed = 0;

    for (final box in _boxes) {
      for (var value = 1; value <= SudokuSolver.boardSize; value++) {
        final indexes = box
            .where(
              (index) => board[index] == 0 && candidates[index].contains(value),
            )
            .toList();

        if (indexes.length < 2) {
          continue;
        }

        final rows = indexes
            .map((index) => index ~/ SudokuSolver.boardSize)
            .toSet();
        final columns = indexes
            .map((index) => index % SudokuSolver.boardSize)
            .toSet();

        if (rows.length == 1) {
          final row = rows.first;
          removed += _removeFromIndexes(
            _rows[row].where((index) => !box.contains(index)),
            candidates,
            value,
          );
        }

        if (columns.length == 1) {
          final column = columns.first;
          removed += _removeFromIndexes(
            _columns[column].where((index) => !box.contains(index)),
            candidates,
            value,
          );
        }

        if (removed > 0) {
          return removed;
        }
      }
    }

    return removed;
  }

  int _applyBoxLineReduction(List<int> board, List<Set<int>> candidates) {
    var removed = 0;

    for (final line in [..._rows, ..._columns]) {
      for (var value = 1; value <= SudokuSolver.boardSize; value++) {
        final indexes = line
            .where(
              (index) => board[index] == 0 && candidates[index].contains(value),
            )
            .toList();

        if (indexes.length < 2) {
          continue;
        }

        final boxes = indexes.map(_boxIndexForCell).toSet();
        if (boxes.length != 1) {
          continue;
        }

        final box = _boxes[boxes.first];
        removed += _removeFromIndexes(
          box.where((index) => !line.contains(index)),
          candidates,
          value,
        );

        if (removed > 0) {
          return removed;
        }
      }
    }

    return removed;
  }

  int _removeFromIndexes(
    Iterable<int> indexes,
    List<Set<int>> candidates,
    int value,
  ) {
    var removed = 0;

    for (final index in indexes) {
      if (candidates[index].remove(value)) {
        removed++;
      }
    }

    return removed;
  }

  bool _canPlace(List<int> board, int row, int column, int value) {
    for (
      var currentColumn = 0;
      currentColumn < SudokuSolver.boardSize;
      currentColumn++
    ) {
      if (board[row * SudokuSolver.boardSize + currentColumn] == value) {
        return false;
      }
    }

    for (
      var currentRow = 0;
      currentRow < SudokuSolver.boardSize;
      currentRow++
    ) {
      if (board[currentRow * SudokuSolver.boardSize + column] == value) {
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

        if (board[index] == value) {
          return false;
        }
      }
    }

    return true;
  }

  void _placeValue(List<int> board, int index, int value) {
    board[index] = value;
  }

  List<SudokuTechnique> _collectUsedTechniques(List<LogicalSolveStep> steps) {
    final techniques = <SudokuTechnique>[];

    for (final step in steps) {
      if (!techniques.contains(step.technique)) {
        techniques.add(step.technique);
      }
    }

    return techniques;
  }

  SudokuTechnique? _maxTechnique(List<SudokuTechnique> techniques) {
    if (techniques.isEmpty) {
      return null;
    }

    return techniques.reduce((current, next) {
      if (next.level > current.level) {
        return next;
      }

      if (next.level == current.level && next.weight > current.weight) {
        return next;
      }

      return current;
    });
  }

  int _calculateScore(
    List<LogicalSolveStep> steps,
    SudokuTechnique? maxTechnique,
  ) {
    final stepScore = steps.fold<int>(
      0,
      (score, step) => score + techniqueWeights[step.technique]!,
    );

    return stepScore + (maxTechnique == null ? 0 : maxTechnique.weight * 3);
  }

  String _classify({
    required List<int> puzzle,
    required int score,
    required SudokuTechnique? maxTechnique,
    required bool requiresSearch,
  }) {
    if (requiresSearch || maxTechnique == SudokuTechnique.search) {
      return 'Uzman';
    }

    final emptyCellCount = puzzle.where((value) => value == 0).length;
    final maxLevel = maxTechnique?.level ?? 0;

    if (maxLevel <= 1) {
      if (emptyCellCount <= 40) {
        return 'Çok Kolay';
      }
      if (emptyCellCount <= 45) {
        return 'Kolay';
      }
      if (emptyCellCount <= 50) {
        return 'Orta';
      }
      if (emptyCellCount <= 55) {
        return 'Zor';
      }
      return 'Uzman';
    }

    if (maxTechnique == SudokuTechnique.nakedPair) {
      if (emptyCellCount <= 45) {
        return 'Kolay';
      }
      if (emptyCellCount <= 50) {
        return 'Orta';
      }
      if (emptyCellCount <= 55) {
        return 'Zor';
      }
      return 'Uzman';
    }

    if (maxLevel == 3) {
      if (emptyCellCount <= 50 && score <= 150) {
        return 'Orta';
      }
      if (emptyCellCount <= 55 || score <= 220) {
        return 'Zor';
      }
      return 'Uzman';
    }

    if (score >= 190 || emptyCellCount >= 56) {
      return 'Uzman';
    }

    return 'Zor';
  }

  void _validateGridShape(List<int> grid) {
    if (grid.length != SudokuSolver.gridSize) {
      throw ArgumentError.value(
        grid.length,
        'grid.length',
        'Sudoku gridi tam olarak 81 elemanlı olmalı.',
      );
    }
  }

  static final List<List<int>> _rows = List<List<int>>.generate(
    SudokuSolver.boardSize,
    (row) => List<int>.generate(
      SudokuSolver.boardSize,
      (column) => row * SudokuSolver.boardSize + column,
    ),
  );

  static final List<List<int>> _columns = List<List<int>>.generate(
    SudokuSolver.boardSize,
    (column) => List<int>.generate(
      SudokuSolver.boardSize,
      (row) => row * SudokuSolver.boardSize + column,
    ),
  );

  static final List<List<int>> _boxes = List<List<int>>.generate(9, (box) {
    final startRow = (box ~/ SudokuSolver.boxSize) * SudokuSolver.boxSize;
    final startColumn = (box % SudokuSolver.boxSize) * SudokuSolver.boxSize;

    return List<int>.generate(9, (offset) {
      final row = startRow + offset ~/ SudokuSolver.boxSize;
      final column = startColumn + offset % SudokuSolver.boxSize;
      return row * SudokuSolver.boardSize + column;
    });
  });

  static final List<List<int>> _units = [..._rows, ..._columns, ..._boxes];

  static int _boxIndexForCell(int index) {
    final row = index ~/ SudokuSolver.boardSize;
    final column = index % SudokuSolver.boardSize;
    return (row ~/ SudokuSolver.boxSize) * SudokuSolver.boxSize +
        column ~/ SudokuSolver.boxSize;
  }

  static List<List<int>> _combinations(List<int> items, int size) {
    final results = <List<int>>[];

    void build(int start, List<int> current) {
      if (current.length == size) {
        results.add(List<int>.from(current));
        return;
      }

      for (var index = start; index < items.length; index++) {
        current.add(items[index]);
        build(index + 1, current);
        current.removeLast();
      }
    }

    build(0, <int>[]);
    return results;
  }
}

class DifficultyAnalysis {
  const DifficultyAnalysis({
    required this.isSolvable,
    required this.isUnique,
    required this.score,
    required this.difficulty,
    required this.usedTechniques,
    required this.maxTechnique,
    required this.logicalSteps,
  });

  factory DifficultyAnalysis.invalid() {
    return const DifficultyAnalysis(
      isSolvable: false,
      isUnique: false,
      score: 0,
      difficulty: 'Geçersiz',
      usedTechniques: <SudokuTechnique>[],
      maxTechnique: null,
      logicalSteps: <LogicalSolveStep>[],
    );
  }

  final bool isSolvable;
  final bool isUnique;
  final int score;
  final String difficulty;
  final List<SudokuTechnique> usedTechniques;
  final SudokuTechnique? maxTechnique;
  final List<LogicalSolveStep> logicalSteps;
}

class LogicalSolveStep {
  const LogicalSolveStep({
    required this.technique,
    required this.description,
    this.cellIndex,
    this.value,
    this.removedCandidates = 0,
  });

  final SudokuTechnique technique;
  final String description;
  final int? cellIndex;
  final int? value;
  final int removedCandidates;
}

class LogicalSolveResult {
  const LogicalSolveResult({required this.isSolved, required this.steps});

  final bool isSolved;
  final List<LogicalSolveStep> steps;
}

class _Placement {
  const _Placement(this.index, this.value);

  final int index;
  final int value;
}
