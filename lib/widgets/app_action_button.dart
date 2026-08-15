import 'package:flutter/material.dart';

class AppActionButton extends StatelessWidget {
  const AppActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isPrimary = true,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 10),
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );

    if (isPrimary) {
      return ElevatedButton(onPressed: onPressed, child: child);
    }

    return OutlinedButton(onPressed: onPressed, child: child);
  }
}
