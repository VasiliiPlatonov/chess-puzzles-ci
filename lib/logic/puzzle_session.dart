import '../models/board.dart';
import '../models/puzzle.dart';

/// Результат попытки хода.
enum MoveResult {
  /// Ход верный, но задача ещё не решена.
  correct,

  /// Ход неверный.
  wrong,

  /// Ход верный, задача решена.
  solved,
}

/// Логика решения одной задачи: проверяет ходы игрока
/// и автоматически делает ответные ходы соперника.
class PuzzleSession {
  /// Создаёт сессию решения задачи с начальной позиции.
  factory PuzzleSession(Puzzle puzzle) {
    final board = Board.fromFen(puzzle.fen);
    return PuzzleSession._(puzzle, board, board.whiteToMove);
  }

  PuzzleSession._(this.puzzle, this._board, this.playerIsWhite);

  /// Решаемая задача.
  final Puzzle puzzle;

  /// true, если игрок играет белыми.
  final bool playerIsWhite;

  Board _board;
  int _step = 0;
  int _mistakes = 0;

  /// Текущая позиция на доске.
  Board get board => _board;

  /// Количество неверных ходов.
  int get mistakes => _mistakes;

  /// true, если все ходы решения сделаны.
  bool get isSolved => _step >= puzzle.solution.length;

  /// Поле, с которого нужно сделать следующий ход (подсказка).
  String? get hintSquare =>
      isSolved ? null : puzzle.solution[_step].substring(0, 2);

  /// Проверяет, стоит ли на поле фигура игрока.
  bool isPlayerPiece(String square) {
    final piece = _board.pieceAt(square);
    return piece != null && Board.isWhitePiece(piece) == playerIsWhite;
  }

  /// Составляет ход в формате UCI по двум полям.
  ///
  /// Пешка, дошедшая до последней горизонтали, превращается в ферзя.
  String buildMove(String from, String to) {
    final piece = _board.pieceAt(from);
    final isPawn = piece == 'P' || piece == 'p';
    final isLastRank = to.endsWith('8') || to.endsWith('1');
    return isPawn && isLastRank ? '$from${to}q' : '$from$to';
  }

  /// Проверяет ход игрока (формат UCI, например «d1d8»).
  MoveResult tryMove(String move) {
    if (isSolved) {
      return MoveResult.solved;
    }
    if (move != puzzle.solution[_step]) {
      _mistakes += 2;
      return MoveResult.wrong;
    }

    _board = _board.applyMove(move);
    _step++;
    if (!isSolved) {
      // Ответный ход соперника выполняется автоматически.
      _board = _board.applyMove(puzzle.solution[_step]);
      _step++;
    }
    return isSolved ? MoveResult.solved : MoveResult.correct;
  }

  /// Возвращает задачу в начальное состояние.
  void reset() {
    _board = Board.fromFen(puzzle.fen);
    _step = 0;
    _mistakes = 0;
  }
}
