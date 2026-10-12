import 'package:chess_puzzles/data/puzzles.dart';
import 'package:chess_puzzles/logic/puzzle_session.dart';
import 'package:chess_puzzles/models/board.dart';
import 'package:chess_puzzles/models/puzzle.dart';
import 'package:flutter_test/flutter_test.dart';

const mateInOne = Puzzle(
  id: 100,
  title: 'Тест: мат в 1 ход',
  fen: '6k1/5ppp/8/8/8/8/5PPP/3R2K1 w - - 0 1',
  solution: ['d1d8'],
  rating: 600,
);

const mateInTwo = Puzzle(
  id: 101,
  title: 'Тест: мат в 2 хода',
  fen: 'r5k1/5ppp/8/8/8/8/3R1PPP/3R2K1 w - - 0 1',
  solution: ['d2d8', 'a8d8', 'd1d8'],
  rating: 900,
);

void main() {
  group('PuzzleSession', () {
    test('верный ход решает задачу на мат в 1 ход', () {
      final session = PuzzleSession(mateInOne);

      expect(session.tryMove('d1d8'), MoveResult.solved);
      expect(session.isSolved, isTrue);
      expect(session.mistakes, 0);
    });

    test('неверный ход не меняет позицию и считается ошибкой', () {
      final session = PuzzleSession(mateInOne);

      expect(session.tryMove('d1d7'), MoveResult.wrong);
      expect(session.mistakes, 1);
      expect(session.board.pieceAt('d1'), 'R');
      expect(session.isSolved, isFalse);
    });

    test('после верного хода соперник отвечает автоматически', () {
      final session = PuzzleSession(mateInTwo);

      expect(session.tryMove('d2d8'), MoveResult.correct);
      // Чёрная ладья взяла белую ладью на d8.
      expect(session.board.pieceAt('d8'), 'r');
      expect(session.board.pieceAt('a8'), isNull);

      expect(session.tryMove('d1d8'), MoveResult.solved);
      expect(session.board.pieceAt('d8'), 'R');
    });

    test('подсказка показывает поле нужной фигуры', () {
      final session = PuzzleSession(mateInTwo);

      expect(session.hintSquare, 'd2');
      session.tryMove('d2d8');
      expect(session.hintSquare, 'd1');
      session.tryMove('d1d8');
      expect(session.hintSquare, isNull);
    });

    test('сброс возвращает начальную позицию', () {
      final session = PuzzleSession(mateInTwo);
      session.tryMove('d2d8');
      session.tryMove('a1a2');

      session.reset();

      expect(session.isSolved, isFalse);
      expect(session.mistakes, 0);
      expect(session.board.pieceAt('d2'), 'R');
      expect(session.hintSquare, 'd2');
    });

    test('пешка на последней горизонтали превращается в ферзя', () {
      final session = PuzzleSession(
        puzzles.firstWhere((puzzle) => puzzle.title == 'Превращение пешки'),
      );

      expect(session.buildMove('e7', 'e8'), 'e7e8q');
      expect(session.buildMove('g6', 'g7'), 'g6g7');
      expect(session.tryMove(session.buildMove('e7', 'e8')), MoveResult.solved);
    });

    test('отличает фигуры игрока от фигур соперника', () {
      final session = PuzzleSession(mateInOne);

      expect(session.playerIsWhite, isTrue);
      expect(session.isPlayerPiece('d1'), isTrue);
      expect(session.isPlayerPiece('g8'), isFalse);
      expect(session.isPlayerPiece('e4'), isFalse);
    });
  });

  group('Встроенные задачи', () {
    test('все позиции корректны, а ходы решения выполнимы', () {
      for (final puzzle in puzzles) {
        var board = Board.fromFen(puzzle.fen);
        for (final move in puzzle.solution) {
          final piece = board.pieceAt(move.substring(0, 2));
          expect(piece, isNotNull, reason: '${puzzle.title}: ход $move');
          expect(
            Board.isWhitePiece(piece!),
            board.whiteToMove,
            reason: '${puzzle.title}: ход $move сделан не той стороной',
          );
          board = board.applyMove(move);
        }
      }
    });

    test('номера задач уникальны', () {
      final ids = puzzles.map((puzzle) => puzzle.id).toSet();

      expect(ids.length, puzzles.length);
    });
  });
}
