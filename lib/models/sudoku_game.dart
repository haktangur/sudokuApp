class SudokuGame {
  SudokuGame({required List<int> puzzle, required List<int> solution})
    : puzzle = List<int>.unmodifiable(puzzle),
      solution = List<int>.unmodifiable(solution);

  final List<int> puzzle;
  final List<int> solution;

  bool isGiven(int index) => puzzle[index] != 0;

  int get emptyCellCount => puzzle.where((value) => value == 0).length;
}
