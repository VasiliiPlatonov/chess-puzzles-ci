import 'package:chess_puzzles/models/board.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Board', () {
    test('читает расстановку фигур из FEN', () {
      final board = Board.fromFen(
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      );

      expect(board.pieceAt('e1'), 'K');
      expect(board.pieceAt('d8'), 'q');
      expect(board.pieceAt('a2'), 'P');
      expect(board.pieceAt('e4'), isNull);
      expect(board.whiteToMove, isTrue);
    });

    test('определяет, чей ход', () {
      final board = Board.fromFen('8/8/8/8/8/8/8/4K2k b - - 0 1');

      expect(board.whiteToMove, isFalse);
    });

    test('выполняет ход и передаёт очередь хода', () {
      final board = Board.fromFen(
        '6k1/5ppp/8/8/8/8/5PPP/3R2K1 w - - 0 1',
      ).applyMove('d1d8');

      expect(board.pieceAt('d1'), isNull);
      expect(board.pieceAt('d8'), 'R');
      expect(board.whiteToMove, isFalse);
    });

    test('выполняет превращение пешки', () {
      final board = Board.fromFen(
        '7k/4P3/6K1/8/8/8/8/8 w - - 0 1',
      ).applyMove('e7e8q');

      expect(board.pieceAt('e7'), isNull);
      expect(board.pieceAt('e8'), 'Q');
    });

    test('переводит названия полей в индексы и обратно', () {
      expect(Board.indexOf('a8'), 0);
      expect(Board.indexOf('h1'), 63);
      expect(Board.squareName(0), 'a8');
      expect(Board.squareName(63), 'h1');
      expect(Board.squareName(Board.indexOf('e4')), 'e4');
    });

    test('отклоняет некорректные ходы и поля', () {
      final board = Board.fromFen('6k1/5ppp/8/8/8/8/5PPP/3R2K1 w - - 0 1');

      expect(() => board.applyMove('d1'), throwsFormatException);
      expect(() => board.applyMove('e4e5'), throwsStateError);
      expect(() => Board.indexOf('i9'), throwsFormatException);
    });

    test('сообщает об ошибке в некорректной позиции', () {
      expect(() => Board.fromFen('8/8/8'), throwsFormatException);
      expect(
        () => Board.fromFen('8/8/8/8/8/8/8/7X w - - 0 1'),
        throwsFormatException,
      );
    });
  });
}
