import 'package:flutter/material.dart';

import '../widgets/app_action_button.dart';
import 'difficulty_screen.dart';
import 'failed_puzzles_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String routeName = '/';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.grid_view_rounded,
                          size: 72,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Sudoku',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sakin, sade ve odaklı bir oyun alanı.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 48),
                        AppActionButton(
                          label: 'Yeni Oyun',
                          icon: Icons.play_arrow_rounded,
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).pushNamed(DifficultyScreen.routeName);
                          },
                        ),
                        const SizedBox(height: 12),
                        AppActionButton(
                          label: 'Çözülemeyenler',
                          icon: Icons.error_outline_rounded,
                          isPrimary: false,
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).pushNamed(FailedPuzzlesScreen.routeName);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
