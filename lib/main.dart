import 'package:flutter/material.dart';

import 'screens/difficulty_screen.dart';
import 'screens/failed_puzzles_screen.dart';
import 'screens/game_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const SudokuApp());
}

class SudokuApp extends StatelessWidget {
  const SudokuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sudoku',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: HomeScreen.routeName,
      routes: {
        HomeScreen.routeName: (_) => const HomeScreen(),
        DifficultyScreen.routeName: (_) => const DifficultyScreen(),
        FailedPuzzlesScreen.routeName: (_) => const FailedPuzzlesScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == GameScreen.routeName) {
          final difficulty = settings.arguments as String? ?? 'Seçilmedi';

          return MaterialPageRoute<void>(
            builder: (_) => GameScreen(difficulty: difficulty),
            settings: settings,
          );
        }

        return null;
      },
    );
  }
}
