/// Шахматная задача: начальная позиция и правильная последовательность ходов.
class Puzzle {
  const Puzzle({
    required this.id,
    required this.title,
    required this.fen,
    required this.solution,
    required this.rating,
  });

  /// Уникальный номер задачи.
  final int id;

  /// Название задачи, которое видит пользователь.
  final String title;

  /// Начальная позиция в нотации FEN.
  final String fen;

  /// Ходы решения в формате UCI (например, «e2e4»).
  ///
  /// Элементы с чётными индексами — ходы игрока,
  /// с нечётными — ответные ходы соперника.
  final List<String> solution;

  /// Условная сложность задачи.
  final int rating;

  /// Количество ходов, которые должен найти игрок.
  int get movesToFind => (solution.length + 1) ~/ 2;

  /// true, если в начальной позиции ход белых.
  bool get whiteToMove {
    final parts = fen.trim().split(' ');
    return parts.length < 2 || parts[1] != 'b';
  }
}
