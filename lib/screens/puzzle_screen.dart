import 'package:flutter/material.dart';

import '../logic/puzzle_session.dart';
import '../models/puzzle.dart';
import '../widgets/chess_board.dart';

/// Экран решения задачи.
class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key, required this.puzzle});

  final Puzzle puzzle;

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  late final PuzzleSession _session;

  /// Поле с выбранной фигурой игрока.
  String? _selected;

  /// Поле, подсвеченное подсказкой.
  String? _hint;

  /// Сообщение над доской.
  String _message = '';

  @override
  void initState() {
    super.initState();
    _session = PuzzleSession(widget.puzzle);
    _message = _startMessage();
  }

  String _startMessage() {
    final side = _session.playerIsWhite ? 'белых' : 'чёрных';
    return 'Ход $side. Найдите лучший ход!';
  }

  /// Обработка нажатия на поле: первое нажатие выбирает фигуру,
  /// второе — делает ход.
  void _onSquareTap(String square) {
    if (_session.isSolved) {
      return;
    }

    final selected = _selected;
    if (selected == null || _session.isPlayerPiece(square)) {
      setState(() {
        final canSelect = _session.isPlayerPiece(square) && square != selected;
        _selected = canSelect ? square : null;
      });
      return;
    }

    final result = _session.tryMove(_session.buildMove(selected, square));
    setState(() {
      _selected = null;
      _hint = null;
      _message = switch (result) {
        MoveResult.correct => 'Верно! Соперник ответил, ваш ход.',
        MoveResult.wrong => 'Неверно, попробуйте ещё раз.',
        MoveResult.solved => 'Задача решена!',
      };
    });
  }

  void _showHint() {
    setState(() {
      _hint = _session.hintSquare;
    });
  }

  void _restart() {
    setState(() {
      _session.reset();
      _selected = null;
      _hint = null;
      _message = _startMessage();
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.puzzle.title)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                _message,
                key: const Key('status-message'),
                style: textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
            Text('Ошибок: ${_session.mistakes}', style: textTheme.bodySmall),
            const SizedBox(height: 12),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ChessBoard(
                    board: _session.board,
                    flipped: !_session.playerIsWhite,
                    selectedSquare: _selected,
                    hintSquare: _hint,
                    onSquareTap: _onSquareTap,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _session.isSolved ? null : _showHint,
                    icon: const Icon(Icons.lightbulb_outline),
                    label: const Text('Подсказка'),
                  ),
                  FilledButton.icon(
                    onPressed: _restart,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Заново'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
