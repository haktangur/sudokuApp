import 'package:flutter/material.dart';

import '../services/game_storage.dart';

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
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Bulmacalar yüklenemedi: $error')));
    }
  }

  Future<void> _deleteGame(int id) async {
    await _storage.deleteFailedGame(id);
    await _loadGames();
  }

  Future<void> _confirmDelete(int id) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Bulmaca silinsin mi?'),
          content: const Text(
            'Bu kaydedilmiş bulmaca kalıcı olarak silinecek.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _deleteGame(id);
    }
  }

  void _openGame(Map<String, dynamic> game) {
    Navigator.pushNamed(
      context,
      '/game',
      arguments: {
        'difficulty': game['difficulty'] as String,
        'failedGame': game,
      },
    );
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
          : RefreshIndicator(
              onRefresh: _loadGames,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _games.length,
                itemBuilder: (context, index) {
                  final game = _games[index];

                  final id = game['id'] as int;
                  final difficulty = game['difficulty'] as String;
                  final elapsed =
                      (game['elapsedSeconds'] as num?)?.toInt() ?? 0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.grid_4x4_rounded),
                      ),
                      title: Text(difficulty),
                      subtitle: Text('Süre: ${_formatTime(elapsed)}'),
                      trailing: IconButton(
                        tooltip: 'Bulmacayı sil',
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () => _confirmDelete(id),
                      ),
                      onTap: () => _openGame(game),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
