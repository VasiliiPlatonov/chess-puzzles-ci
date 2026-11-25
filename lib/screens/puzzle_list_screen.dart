import 'package:flutter/material.dart';

import '../data/puzzles.dart';
import '../models/puzzle.dart';
import 'puzzle_screen.dart';

/// Главный экран: список задач.
class PuzzleListScreen extends StatelessWidget {
  const PuzzleListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Шахматные задачи')),
      body: ListView.separated(
        itemCount: puzzles.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final puzzle = puzzles[index];
          return ListTile(
            key: Key('puzzle-${puzzle.id}'),
            leading: CircleAvatar(child: Text('${puzzle.id}')),
            title: Text(puzzle.title),
            subtitle: Text(_subtitle(puzzle)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => PuzzleScreen(puzzle: puzzle),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Подпись под названием задачи, например «Ход белых · мат в 2 хода».
  String _subtitle(Puzzle puzzle) {
    final side = puzzle.whiteToMove ? 'белых' : 'чёрных';
    final moves = puzzle.movesToFind;
    final word = moves == 1 ? 'ход' : 'хода';
    return 'Ход $side · мат в $moves $word · рейтинг ${puzzle.rating}';
  }
}
