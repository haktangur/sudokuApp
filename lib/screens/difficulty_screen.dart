import 'package:flutter/material.dart';

import 'game_screen.dart';

class DifficultyScreen extends StatelessWidget {
  const DifficultyScreen({super.key});

  static const String routeName = '/difficulty';
  static const List<String> _difficulties = [
    'Çok Kolay',
    'Kolay',
    'Orta',
    'Zor',
    'Uzman',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zorluk Seç')),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: _difficulties.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final difficulty = _difficulties[index];

            return FilledButton.tonal(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(58),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
              onPressed: () {
                Navigator.of(
                  context,
                ).pushNamed(GameScreen.routeName, arguments: difficulty);
              },
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      difficulty,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
