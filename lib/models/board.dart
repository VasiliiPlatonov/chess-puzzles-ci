/// Шахматная доска, построенная по позиции в нотации FEN.
///
/// Фигуры хранятся буквами FEN: заглавные — белые (K, Q, R, B, N, P),
/// строчные — чёрные (k, q, r, b, n, p). Пустое поле — null.
class Board {
  Board._(this._squares, this.whiteToMove);

  /// Создаёт доску из строки FEN.
  ///
  /// Используются только два первых поля FEN: расстановка фигур
  /// и очередь хода. Остальные поля (рокировки, взятие на проходе,
  /// счётчики ходов) для решения задач не нужны.
  factory Board.fromFen(String fen) {
    final parts = fen.trim().split(' ');
    final rows = parts[0].split('/');
    if (rows.length != 8) {
      throw FormatException('В позиции должно быть 8 горизонталей', fen);
    }

    final squares = <String?>[];
    for (final row in rows) {
      var count = 0;
      for (final char in row.split('')) {
        final emptySquares = int.tryParse(char);
        if (emptySquares != null) {
          squares.addAll(List<String?>.filled(emptySquares, null));
          count += emptySquares;
        } else if (_pieceLetters.contains(char)) {
          squares.add(char);
          count += 1;
        } else {
          throw FormatException('Неизвестный символ «$char»', fen);
        }
      }
      if (count != 8) {
        throw FormatException('В горизонтали должно быть 8 полей', fen);
      }
    }

    final whiteToMove = parts.length < 2 || parts[1] != 'b';
    return Board._(squares, whiteToMove);
  }

  static const String _pieceLetters = 'KQRBNPkqrbnp';

  /// 64 поля доски. Индекс 0 — поле a8, индекс 63 — поле h1.
  final List<String?> _squares;

  /// true, если сейчас ход белых.
  final bool whiteToMove;

  /// Возвращает фигуру на поле (например, «e4») или null, если поле пустое.
  String? pieceAt(String square) => _squares[indexOf(square)];

  /// Проверяет, является ли фигура белой.
  static bool isWhitePiece(String piece) => piece == piece.toUpperCase();

  /// Выполняет ход в формате UCI и возвращает новую доску.
  ///
  /// Соответствие хода правилам шахмат здесь не проверяется:
  /// приложение выполняет только ходы из решения задачи.
  /// Пятый символ хода (например, «e7e8q») означает превращение пешки.
  Board applyMove(String move) {
    if (move.length != 4 && move.length != 5) {
      throw FormatException('Некорректный ход', move);
    }
    final from = indexOf(move.substring(0, 2));
    final to = indexOf(move.substring(2, 4));
    final piece = _squares[from];
    if (piece == null) {
      throw StateError('На поле ${move.substring(0, 2)} нет фигуры');
    }

    final squares = List<String?>.of(_squares);
    squares[from] = null;
    if (move.length == 5) {
      final promoted = move[4];
      squares[to] =
          isWhitePiece(piece) ? promoted.toUpperCase() : promoted.toLowerCase();
    } else {
      squares[to] = piece;
    }
    return Board._(squares, !whiteToMove);
  }

  /// Преобразует название поля (например, «e4») в индекс от 0 до 63.
  static int indexOf(String square) {
    if (square.length != 2) {
      throw FormatException('Некорректное поле', square);
    }
    final file = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = square.codeUnitAt(1) - '1'.codeUnitAt(0);
    if (file < 0 || file > 7 || rank < 0 || rank > 7) {
      throw FormatException('Некорректное поле', square);
    }
    return (7 - rank) * 8 + file;
  }

  /// Преобразует индекс от 0 до 63 в название поля (например, «e4»).
  static String squareName(int index) {
    final file = String.fromCharCode('a'.codeUnitAt(0) + index % 8);
    final rank = 8 - index ~/ 8;
    return '$file$rank';
  }
}
