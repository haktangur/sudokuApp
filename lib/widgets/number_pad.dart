import 'package:flutter/material.dart';

class NumberPad extends StatelessWidget {
  const NumberPad({
    required this.onNumber,
    required this.onNotesToggle,
    required this.notesMode,
    super.key,
  });

  final ValueChanged<int> onNumber;
  final VoidCallback onNotesToggle;
  final bool notesMode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          children: List.generate(
            5,
            (index) => Expanded(
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: _NumberButton(
                  number: index + 1,
                  onTap: () => onNumber(index + 1),
                ),
              ),
            ),
          ),
        ),
        Row(
          children: [
            for (var index = 0; index < 4; index++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: _NumberButton(
                    number: index + 6,
                    onTap: () => onNumber(index + 6),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onNotesToggle,
            icon: Icon(notesMode ? Icons.edit_note : Icons.edit_note_outlined),
            label: Text(notesMode ? 'Not modu açık' : 'Not modu'),
            style: OutlinedButton.styleFrom(
              foregroundColor: notesMode
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _NumberButton extends StatelessWidget {
  const _NumberButton({required this.number, required this.onTap});

  final int number;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FilledButton.tonal(
        onPressed: onTap,
        child: Text(
          '$number',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
