import 'package:flutter/material.dart';

import '../models/sudoku_game.dart';
import '../services/sudoku_generator.dart';
import '../widgets/number_pad.dart';
import '../widgets/sudoku_board.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({required this.difficulty, super.key});

  static const String routeName = '/game';

  final String difficulty;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final SudokuGenerator _generator = SudokuGenerator();

  SudokuGame? _game;
  List<int> _values = [];
  List<Set<int>> _notes = [];
  int? _selectedIndex;
  int _mistakes = 0;
  bool _notesMode = false;
  bool _gameOver = false;
  bool _won = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    setState(() {
      _loading = true;
      _game = null;
      _selectedIndex = null;
      _mistakes = 0;
      _notesMode = false;
      _gameOver = false;
      _won = false;
    });

    try {
      final generated = _generator.generateGame(widget.difficulty);

      final game = SudokuGame(
        puzzle: generated.puzzle,
        solution: generated.solution,
      );

      setState(() {
        _game = game;
        _values = List<int>.from(game.puzzle);
        _notes = List.generate(81, (_) => <int>{});
        _loading = false;
      });
    } catch (error) {
      setState(() {
        _loading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sudoku oluşturulamadı: $error')),
        );
      }
    }
  }

  void _restartGame() {
    final game = _game;
    if (game == null) return;

    setState(() {
      _values = List<int>.from(game.puzzle);
      _notes = List.generate(81, (_) => <int>{});
      _selectedIndex = null;
      _mistakes = 0;
      _notesMode = false;
      _gameOver = false;
      _won = false;
    });
  }

  void _selectCell(int index) {
    if (_gameOver || _won) return;

    setState(() {
      _selectedIndex = index;
    });
  }

  void _enterNumber(int number) {
    final game = _game;
    final index = _selectedIndex;

    if (game == null ||
        index == null ||
        _gameOver ||
        _won ||
        game.isGiven(index)) {
      return;
    }

    if (_notesMode) {
      setState(() {
        if (_notes[index].contains(number)) {
          _notes[index].remove(number);
        } else {
          _notes[index].add(number);
        }
      });
      return;
    }

    if (game.solution[index] != number) {
      setState(() {
        _mistakes++;
      });

      if (_mistakes >= 3) {
        setState(() {
          _gameOver = true;
        });

        _showGameOverDialog();
      }

      return;
    }

    setState(() {
      _values[index] = number;
      _notes[index].clear();
    });

    if (_values.every((value) => value != 0)) {
      setState(() {
        _won = true;
      });

      _showWinDialog();
    }
  }

  Future<void> _confirmStartNewGame() async {
    final shouldStart = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Yeni bulmaca başlatılsın mı?'),
          content: const Text(
            'Mevcut bulmacadaki ilerlemeniz kaybolacak ve yeni bir bulmaca '
            'oluşturulacak.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yeni Bulmaca'),
            ),
          ],
        );
      },
    );

    if (shouldStart == true && mounted) {
      _startNewGame();
    }
  }

  void _showGameOverDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('Oyun bitti'),
            content: const Text(
              'Üç hata yaptın. Bu bulmacayı daha sonra tekrar '
              'deneyebilirsin.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _restartGame();
                },
                child: const Text('Tekrar dene'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  _startNewGame();
                },
                child: const Text('Yeni bulmaca'),
              ),
            ],
          );
        },
      );
    });
  }

  void _showWinDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('Tebrikler! 🎉'),
            content: Text('${widget.difficulty} bulmacayı tamamladın.'),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  _startNewGame();
                },
                child: const Text('Yeni bulmaca'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Ana menü'),
              ),
            ],
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.difficulty),
        actions: [
          IconButton(
            onPressed: _loading ? null : _confirmStartNewGame,
            tooltip: 'Yeni bulmaca',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _game == null
            ? _buildErrorState()
            : LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding = constraints.maxWidth < 500
                      ? 12.0
                      : 24.0;

                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      12,
                      horizontalPadding,
                      24,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _DifficultyBadge(difficulty: widget.difficulty),
                                const Spacer(),
                                _MistakeIndicator(mistakes: _mistakes),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SudokuBoard(
                              puzzle: _game!.puzzle,
                              values: _values,
                              notes: _notes,
                              selectedIndex: _selectedIndex,
                              onCellTap: _selectCell,
                            ),
                            const SizedBox(height: 18),
                            Text(
                              _notesMode
                                  ? 'Not eklemek için bir hücre seç'
                                  : 'Bir hücre seç ve rakam gir',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 12),
                            NumberPad(
                              onNumber: _enterNumber,
                              onNotesToggle: () {
                                setState(() {
                                  _notesMode = !_notesMode;
                                });
                              },
                              notesMode: _notesMode,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 56),
            const SizedBox(height: 16),
            const Text('Bulmaca oluşturulamadı.', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _startNewGame,
              child: const Text('Tekrar dene'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty});

  final String difficulty;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        difficulty,
        style: TextStyle(
          color: colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MistakeIndicator extends StatelessWidget {
  const _MistakeIndicator({required this.mistakes});

  final int mistakes;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final used = index < mistakes;

        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Icon(
            used ? Icons.close_rounded : Icons.favorite_rounded,
            size: 20,
            color: used ? colorScheme.error : colorScheme.primary,
          ),
        );
      }),
    );
  }
}
