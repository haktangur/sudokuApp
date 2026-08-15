import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/services/sudoku_difficulty_analyzer.dart';

void main() {
  const analyzer = SudokuDifficultyAnalyzer();

  const easyPuzzle = [
    0,
    3,
    4,
    6,
    7,
    8,
    9,
    1,
    2,
    6,
    7,
    2,
    1,
    9,
    5,
    3,
    4,
    8,
    1,
    9,
    8,
    3,
    4,
    2,
    5,
    6,
    7,
    8,
    5,
    9,
    7,
    6,
    1,
    4,
    2,
    3,
    4,
    2,
    6,
    8,
    5,
    3,
    7,
    9,
    1,
    7,
    1,
    3,
    9,
    2,
    4,
    8,
    5,
    6,
    9,
    6,
    1,
    5,
    3,
    7,
    2,
    8,
    4,
    2,
    8,
    7,
    4,
    1,
    9,
    6,
    3,
    5,
    3,
    4,
    5,
    2,
    8,
    6,
    1,
    7,
    9,
  ];

  const hardPuzzle = [
    1,
    0,
    0,
    0,
    0,
    7,
    0,
    9,
    0,
    0,
    3,
    0,
    0,
    2,
    0,
    0,
    0,
    8,
    0,
    0,
    9,
    6,
    0,
    0,
    5,
    0,
    0,
    0,
    0,
    5,
    3,
    0,
    0,
    9,
    0,
    0,
    0,
    1,
    0,
    0,
    8,
    0,
    0,
    0,
    2,
    6,
    0,
    0,
    0,
    0,
    4,
    0,
    0,
    0,
    3,
    0,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    4,
    0,
    0,
    0,
    0,
    0,
    0,
    7,
    0,
    0,
    7,
    0,
    0,
    0,
    3,
    0,
    0,
  ];

  const solvedGrid = [
    5,
    3,
    4,
    6,
    7,
    8,
    9,
    1,
    2,
    6,
    7,
    2,
    1,
    9,
    5,
    3,
    4,
    8,
    1,
    9,
    8,
    3,
    4,
    2,
    5,
    6,
    7,
    8,
    5,
    9,
    7,
    6,
    1,
    4,
    2,
    3,
    4,
    2,
    6,
    8,
    5,
    3,
    7,
    9,
    1,
    7,
    1,
    3,
    9,
    2,
    4,
    8,
    5,
    6,
    9,
    6,
    1,
    5,
    3,
    7,
    2,
    8,
    4,
    2,
    8,
    7,
    4,
    1,
    9,
    6,
    3,
    5,
    3,
    4,
    5,
    2,
    8,
    6,
    1,
    7,
    9,
  ];

  test('kolay puzzle dusuk difficulty alir', () {
    final analysis = analyzer.analyze(easyPuzzle);

    expect(analysis.isSolvable, isTrue);
    expect(analysis.isUnique, isTrue);
    expect(['Çok Kolay', 'Kolay'], contains(analysis.difficulty));
  });

  test(
    'ileri teknik veya search gerektiren puzzle daha yuksek difficulty alir',
    () {
      final easyAnalysis = analyzer.analyze(easyPuzzle);
      final hardAnalysis = analyzer.analyze(hardPuzzle);

      expect(hardAnalysis.isSolvable, isTrue);
      expect(hardAnalysis.isUnique, isTrue);
      expect(
        _difficultyRank(hardAnalysis.difficulty),
        greaterThan(_difficultyRank(easyAnalysis.difficulty)),
      );
    },
  );

  test('unique olmayan puzzle kabul edilmez', () {
    final multiSolutionPuzzle = solvedGrid
        .map((value) => value == 1 || value == 2 ? 0 : value)
        .toList();
    final analysis = analyzer.analyze(multiSolutionPuzzle);

    expect(analysis.isSolvable, isTrue);
    expect(analysis.isUnique, isFalse);
    expect(analysis.difficulty, 'Geçersiz');
  });

  test('cozulemeyen veya invalid puzzle dogru raporlanir', () {
    final invalidPuzzle = List<int>.from(easyPuzzle)..[1] = 5;
    final analysis = analyzer.analyze(invalidPuzzle);

    expect(analysis.isSolvable, isFalse);
    expect(analysis.isUnique, isFalse);
    expect(analysis.difficulty, 'Geçersiz');
  });

  test('kullanilan teknikleri raporlar', () {
    final analysis = analyzer.analyze(easyPuzzle);

    expect(analysis.usedTechniques, isNotEmpty);
    expect(analysis.logicalSteps, isNotEmpty);
  });

  test('maxTechnique bilgisi dogrudur', () {
    final analysis = analyzer.analyze(hardPuzzle);
    final expectedMax = analysis.usedTechniques.reduce((current, next) {
      if (next.level > current.level) {
        return next;
      }

      if (next.level == current.level && next.weight > current.weight) {
        return next;
      }

      return current;
    });

    expect(analysis.maxTechnique, expectedMax);
  });

  test('difficulty score deterministiktir', () {
    final firstAnalysis = analyzer.analyze(hardPuzzle);
    final secondAnalysis = analyzer.analyze(hardPuzzle);

    expect(firstAnalysis.score, secondAnalysis.score);
    expect(firstAnalysis.difficulty, secondAnalysis.difficulty);
  });
}

int _difficultyRank(String difficulty) {
  return SudokuDifficultyAnalyzer.difficulties.indexOf(difficulty);
}
