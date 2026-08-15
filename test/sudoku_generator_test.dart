import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/services/sudoku_generator.dart';
import 'package:sudoku/services/sudoku_solver.dart';

void main() {
  const solver = SudokuSolver();

  test('uretilen puzzle 81 hucre icerir ve yalnizca 0-9 degerleri tasir', () {
    final generator = SudokuGenerator(random: Random(1));
    final puzzle = generator.generatePuzzle('Çok Kolay');

    expect(puzzle, hasLength(81));
    expect(puzzle.every((value) => value >= 0 && value <= 9), isTrue);
  });

  test('uretilen puzzle tam olarak 1 cozume sahiptir', () {
    final generator = SudokuGenerator(random: Random(2));
    final puzzle = generator.generatePuzzle('Kolay');

    expect(solver.countSolutions(puzzle), 1);
  });

  test('her difficulty seviyesi icin puzzle uretebilir', () {
    final generator = SudokuGenerator(random: Random(3));

    for (final difficulty in SudokuGenerator.difficultyTargets.keys) {
      final puzzle = generator.generatePuzzle(difficulty);
      final emptyCellCount = puzzle.where((value) => value == 0).length;
      final target = SudokuGenerator.difficultyTargets[difficulty]!;

      expect(puzzle, hasLength(81));
      expect(
        emptyCellCount,
        inInclusiveRange(target.minEmptyCells, target.maxEmptyCells),
      );
      expect(solver.countSolutions(puzzle), 1);
    }
  });

  test('ayni generator instance tekrar eden fingerprint dondurmez', () {
    final generator = SudokuGenerator(random: Random(4));
    final firstPuzzle = generator.generatePuzzle('Çok Kolay');
    final secondPuzzle = generator.generatePuzzle('Çok Kolay');

    expect(
      generator.createFingerprint(firstPuzzle),
      isNot(generator.createFingerprint(secondPuzzle)),
    );
  });

  test('generator basarisiz oldugunda sonsuz donguye girmez', () {
    final generator = SudokuGenerator(random: Random(5), maxAttempts: 0);

    expect(
      () => generator.generatePuzzle('Çok Kolay'),
      throwsA(isA<SudokuGenerationException>()),
    );
  });
}
