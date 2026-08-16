import 'package:flutter/material.dart';

import '../services/game_storage.dart';
import 'game_screen.dart';

class FailedPuzzlesScreen extends StatefulWidget {
  const FailedPuzzlesScreen({super.key});

  static const String routeName = '/failed-puzzles';

  @override
  State<FailedPuzzlesScreen> createState() => _FailedPuzzlesScreenState();
}

class _FailedPuzzlesScreenState extends State<FailedPuzzlesScreen> {
  final GameStorage _storage = GameStorage();

  List<Map<String, dynamic>> _games = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    try {
      final games = await _storage.loadFailedGames();

      if (!mounted) return;

      setState(() {
        _games = games;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _games = [];
        _loading = false;
      });
    }
  }

  Future<void> _deleteGame(int id) async {
    await _storage.deleteFailedGame(id);
    await _loadGames();
  }

  Future<void> _openGame(Map<String, dynamic> game) async {
    try {
      final savedGame = SavedGame.fromJson(game);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GameScreen(
            difficulty: savedGame.difficulty,
            savedGame: savedGame,
          ),
        ),
      );

      if (mounted) {
        await _loadGames();
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Bulmaca açılamadı: $error')));
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Çözülemeyen Bulmacalar')),
      body: _games.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Henüz kaybedilmiş bir bulmaca yok.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _games.length,
              itemBuilder: (context, index) {
                final game = _games[index];

                final id = game['id'] as int;
                final difficulty = game['difficulty'] as String;
                final elapsed = game['elapsedSeconds'] as int;
                final mistakes = game['mistakes'] as int;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.grid_4x4_rounded),
                    title: Text(difficulty),
                    subtitle: Text(
                      'Süre: ${_formatTime(elapsed)}  •  Hata: $mistakes/3',
                    ),
                    trailing: IconButton(
                      tooltip: 'Bulmacayı sil',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteGame(id),
                    ),
                    onTap: () => _openGame(game),
                  ),
                );
              },
            ),
    );
  }
}
