import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SavedGame {
  const SavedGame({
    required this.difficulty,
    required this.puzzle,
    required this.solution,
    required this.values,
    required this.notes,
    required this.mistakes,
    required this.elapsedSeconds,
  });

  final String difficulty;
  final List<int> puzzle;
  final List<int> solution;
  final List<int> values;
  final List<Set<int>> notes;
  final int mistakes;
  final int elapsedSeconds;

  Map<String, dynamic> toJson() {
    return {
      'difficulty': difficulty,
      'puzzle': puzzle,
      'solution': solution,
      'values': values,
      'notes': notes.map((note) => note.toList()).toList(),
      'mistakes': mistakes,
      'elapsedSeconds': elapsedSeconds,
    };
  }

  factory SavedGame.fromJson(Map<String, dynamic> json) {
    final rawNotes = json['notes'] as List<dynamic>;

    return SavedGame(
      difficulty: json['difficulty'] as String,
      puzzle: List<int>.from(json['puzzle'] as List<dynamic>),
      solution: List<int>.from(json['solution'] as List<dynamic>),
      values: List<int>.from(json['values'] as List<dynamic>),
      notes: rawNotes
          .map((note) => Set<int>.from(note as List<dynamic>))
          .toList(),
      mistakes: json['mistakes'] as int,
      elapsedSeconds: json['elapsedSeconds'] as int,
    );
  }
}

class GameStorage {
  static const String _activeGameKey = 'active_sudoku_game';
  static const String _failedGamesKey = 'failed_sudoku_games';

  Future<void> saveGame(SavedGame game) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(_activeGameKey, jsonEncode(game.toJson()));
  }

  Future<SavedGame?> loadGame() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_activeGameKey);

    if (raw == null) {
      return null;
    }

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return SavedGame.fromJson(json);
    } catch (_) {
      await clearGame();
      return null;
    }
  }

  Future<void> clearGame() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_activeGameKey);
  }

  Future<List<Map<String, dynamic>>> loadFailedGames() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_failedGamesKey);

    if (raw == null) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;

      return decoded
          .map(
            (game) => Map<String, dynamic>.from(game as Map<dynamic, dynamic>),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveFailedGame(SavedGame game) async {
    final preferences = await SharedPreferences.getInstance();

    final games = await loadFailedGames();

    final failedGame = {
      'id': DateTime.now().millisecondsSinceEpoch,
      ...game.toJson(),
    };

    games.insert(0, failedGame);

    await preferences.setString(_failedGamesKey, jsonEncode(games));
  }

  Future<void> deleteFailedGame(int id) async {
    final preferences = await SharedPreferences.getInstance();

    final games = await loadFailedGames();

    games.removeWhere((game) => game['id'] == id);

    await preferences.setString(_failedGamesKey, jsonEncode(games));
  }
}
