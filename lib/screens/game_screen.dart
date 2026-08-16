import 'dart:async';

import 'package:flutter/material.dart';

import '../models/sudoku_game.dart';
import '../services/game_storage.dart';
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

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  final SudokuGenerator _generator = SudokuGenerator();
  final GameStorage _storage = GameStorage();

  SudokuGame? _game;
  List<int> _values = [];
  List<Set<int>> _notes = [];

  int? _selectedIndex;
  int _mistakes = 0;
  int _elapsedSeconds = 0;

  bool _notesMode = false;
  bool _gameOver = false;
  bool _won = false;
  bool _loading = true;
  bool _restoredGame = false;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadGame();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _saveCurrentGame();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _saveCurrentGame();
    }
  }

  Future<void> _loadGame() async {
    try {
      final saved = await _storage.loadGame();

      if (saved != null &&
          saved.difficulty == widget.difficulty &&
          saved.puzzle.length == 81 &&
          saved.solution.length == 81 &&
          saved.values.length == 81 &&
          saved.notes.length == 81) {
        final game = SudokuGame(puzzle: saved.puzzle, solution: saved.solution);

        if (!mounted) return;

        setState(() {
          _game = game;
          _values = List<int>.from(saved.values);
          _notes = saved.notes.map((note) => Set<int>.from(note)).toList();
          _mistakes = saved.mistakes;
          _elapsedSeconds = saved.elapsedSeconds;
          _loading = false;
          _restoredGame = true;
        });

        _startTimer();
        return;
      }

      await _startNewGame(clearSaved: false);
    } catch (_) {
      await _startNewGame(clearSaved: false);
    }
  }

  Future<void> _startNewGame({bool clearSaved = true}) async {
    _timer?.cancel();

    if (clearSaved) {
      await _storage.clearGame();
    }

    if (!mounted) return;

    setState(() {
      _loading = true;
      _game = null;
      _values = [];
      _notes = [];
      _selectedIndex = null;
      _mistakes = 0;
      _elapsedSeconds = 0;
      _notesMode = false;
      _gameOver = false;
      _won = false;
      _restoredGame = false;
    });

    try {
      final generated = _generator.generateGame(widget.difficulty);

      final game = SudokuGame(
        puzzle: generated.puzzle,
        solution: generated.solution,
      );

      if (!mounted) return;

      setState(() {
        _game = game;
        _values = List<int>.from(game.puzzle);
        _notes = List.generate(81, (_) => <int>{});
        _loading = false;
      });

      _startTimer();
      await _saveCurrentGame();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sudoku oluşturulamadı: $error')));
    }
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _gameOver || _won) return;

      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  Future<void> _saveCurrentGame() async {
    final game = _game;

    if (game == null || _gameOver || _won) {
      return;
    }

    await _storage.saveGame(
      SavedGame(
        difficulty: widget.difficulty,
        puzzle: List<int>.from(game.puzzle),
        solution: List<int>.from(game.solution),
        values: List<int>.from(_values),
        notes: _notes.map((note) => Set<int>.from(note)).toList(),
        mistakes: _mistakes,
        elapsedSeconds: _elapsedSeconds,
      ),
    );
  }

  Future<void> _restartGame() async {
    final game = _game;

    if (game == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Bulmacayı sıfırla?'),
          content: const Text(
            'Bu bulmacadaki ilerlemeniz, notlarınız ve süre sıfırlanacak.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sıfırla'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _values = List<int>.from(game.puzzle);
      _notes = List.generate(81, (_) => <int>{});
      _selectedIndex = null;
      _mistakes = 0;
      _elapsedSeconds = 0;
      _notesMode = false;
      _gameOver = false;
      _won = false;
    });

    _startTimer();
    await _saveCurrentGame();
  }

  void _selectCell(int index) {
    if (_gameOver || _won) return;

    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _enterNumber(int number) async {
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

      await _saveCurrentGame();
      return;
    }

    if (game.solution[index] != number) {
      setState(() {
        _mistakes++;
      });

      await _saveCurrentGame();

      if (_mistakes >= 3) {
        _timer?.cancel();

        setState(() {
          _gameOver = true;
        });

        await _storage.saveFailedGame(
          SavedGame(
            difficulty: widget.difficulty,
            puzzle: List<int>.from(game.puzzle),
            solution: List<int>.from(game.solution),
            values: List<int>.from(_values),
            notes: _notes.map((note) => Set<int>.from(note)).toList(),
            mistakes: _mistakes,
            elapsedSeconds: _elapsedSeconds,
          ),
        );

        await _storage.clearGame();

        if (mounted) {
          _showGameOverDialog();
        }
      }

      return;
    }

    setState(() {
      _values[index] = number;
      _notes[index].clear();
    });

    if (_values.every((value) => value != 0)) {
      _timer?.cancel();

      setState(() {
        _won = true;
      });

      await _storage.clearGame();

      if (mounted) {
        _showWinDialog();
      }

      return;
    }

    await _saveCurrentGame();
  }

  Future<void> _confirmStartNewGame() async {
    final shouldStart = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Yeni bulmaca başlatılsın mı?'),
          content: const Text(
            'Mevcut bulmacadaki ilerlemeniz ve süreniz kaybolacak. '
            'Yeni bir Sudoku oluşturulacak.',
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
      await _startNewGame();
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
              'Üç hata yaptın. Bu bulmacayı tekrar deneyebilirsin.',
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
            content: Text(
              '${widget.difficulty} bulmacayı ${_formatTime(_elapsedSeconds)} '
              'sürede tamamladın.',
            ),
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

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
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
            onPressed: _loading ? null : _restartGame,
            tooltip: 'Bulmacayı sıfırla',
            icon: const Icon(Icons.restart_alt_rounded),
          ),
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
                                _TimerDisplay(elapsedSeconds: _elapsedSeconds),
                                const SizedBox(width: 14),
                                _MistakeIndicator(mistakes: _mistakes),
                              ],
                            ),
                            if (_restoredGame) ...[
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Kaldığın yerden devam ediyorsun',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
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

class _TimerDisplay extends StatelessWidget {
  const _TimerDisplay({required this.elapsedSeconds});

  final int elapsedSeconds;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.timer_outlined, size: 20),
        const SizedBox(width: 5),
        Text(
          _formatTime(elapsedSeconds),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
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
