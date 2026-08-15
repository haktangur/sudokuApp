import 'package:flutter/material.dart';

class SudokuBoard extends StatelessWidget {
  const SudokuBoard({
    required this.puzzle,
    required this.values,
    required this.notes,
    required this.selectedIndex,
    required this.onCellTap,
    super.key,
  });

  final List<int> puzzle;
  final List<int> values;
  final List<Set<int>> notes;
  final int? selectedIndex;
  final ValueChanged<int> onCellTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border.all(color: colorScheme.onSurface, width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 81,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 9,
          ),
          itemBuilder: (context, index) {
            return _SudokuCell(
              value: values[index],
              isGiven: puzzle[index] != 0,
              notes: notes[index],
              selected: selectedIndex == index,
              onTap: () => onCellTap(index),
              rightBorder: index % 9 == 2 || index % 9 == 5,
              bottomBorder: index ~/ 9 == 2 || index ~/ 9 == 5,
              colorScheme: colorScheme,
            );
          },
        ),
      ),
    );
  }
}

class _SudokuCell extends StatelessWidget {
  const _SudokuCell({
    required this.value,
    required this.isGiven,
    required this.notes,
    required this.selected,
    required this.onTap,
    required this.rightBorder,
    required this.bottomBorder,
    required this.colorScheme,
  });

  final int value;
  final bool isGiven;
  final Set<int> notes;
  final bool selected;
  final VoidCallback onTap;
  final bool rightBorder;
  final bool bottomBorder;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? colorScheme.primaryContainer : colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: colorScheme.outlineVariant,
                width: rightBorder ? 1.8 : 0.5,
              ),
              bottom: BorderSide(
                color: colorScheme.outlineVariant,
                width: bottomBorder ? 1.8 : 0.5,
              ),
            ),
          ),
          child: value != 0
              ? Center(
                  child: Text(
                    '$value',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: isGiven ? FontWeight.w700 : FontWeight.w500,
                      color: isGiven
                          ? colorScheme.onSurface
                          : colorScheme.primary,
                    ),
                  ),
                )
              : _NotesGrid(notes: notes, color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _NotesGrid extends StatelessWidget {
  const _NotesGrid({required this.notes, required this.color});

  final Set<int> notes;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(2),
      itemCount: 9,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
      ),
      itemBuilder: (context, index) {
        final number = index + 1;

        return Center(
          child: Text(
            notes.contains(number) ? '$number' : '',
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      },
    );
  }
}
