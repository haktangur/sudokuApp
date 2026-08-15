import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/services/sudoku_solver.dart';

void main() {
  const solver = SudokuSolver();

  const validPuzzle = [
    5,
    3,
    0,
    0,
    7,
    0,
    0,
    0,
    0,
    6,
    0,
    0,
    1,
    9,
    5,
    0,
    0,
    0,
    0,
    9,
    8,
    0,
    0,
    0,
    0,
    6,
    0,
    8,
    0,
    0,
    0,
    6,
    0,
    0,
    0,
    3,
    4,
    0,
    0,
    8,
    0,
    3,
    0,
    0,
    1,
    7,
    0,
    0,
    0,
    2,
    0,
    0,
    0,
    6,
    0,
    6,
    0,
    0,
    0,
    0,
    2,
    8,
    0,
    0,
    0,
    0,
    4,
    1,
    9,
    0,
    0,
    5,
    0,
    0,
    0,
    0,
    8,
    0,
    0,
    7,
    9,
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

  test('bilinen gecerli Sudoku dogru cozulur', () {
    expect(solver.solve(validPuzzle), solvedGrid);
  });

  test('tek cozumlu Sudoku 1 solution count dondurur', () {
    expect(solver.countSolutions(validPuzzle), 1);
    expect(solver.hasUniqueSolution(validPuzzle), isTrue);
  });

  test('birden fazla cozumlu grid 2+ olarak algilanir', () {
    final multiSolutionGrid = solvedGrid
        .map((value) => value == 1 || value == 2 ? 0 : value)
        .toList();

    expect(solver.countSolutions(multiSolutionGrid), 2);
    expect(solver.hasUniqueSolution(multiSolutionGrid), isFalse);
  });

  test('cozumu olmayan gecerli baslangic gridini algilar', () {
    const unsolvablePuzzle = [
      0,
      3,
      4,
      6,
      7,
      8,
      9,
      1,
      2,
      5,
      7,
      2,
      1,
      9,
      0,
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

    expect(solver.isValidPuzzle(unsolvablePuzzle), isTrue);
    expect(solver.solve(unsolvablePuzzle), isNull);
    expect(solver.countSolutions(unsolvablePuzzle), 0);
  });

  test('tamamen cozulmus gecerli Sudoku kabul edilir', () {
    expect(solver.isValidPuzzle(solvedGrid), isTrue);
    expect(solver.solve(solvedGrid), solvedGrid);
    expect(solver.countSolutions(solvedGrid), 1);
  });

  test('gecersiz baslangic gridini reddeder', () {
    final invalidPuzzle = List<int>.from(validPuzzle)..[2] = 5;

    expect(solver.isValidPuzzle(invalidPuzzle), isFalse);
    expect(solver.solve(invalidPuzzle), isNull);
    expect(solver.countSolutions(invalidPuzzle), 0);
  });

  test('81 elemandan farkli grid icin hata verir', () {
    expect(
      () => solver.isValidPuzzle(List<int>.filled(80, 0)),
      throwsArgumentError,
    );
    expect(() => solver.solve(List<int>.filled(82, 0)), throwsArgumentError);
    expect(
      () => solver.countSolutions(List<int>.filled(80, 0)),
      throwsArgumentError,
    );
  });
}
