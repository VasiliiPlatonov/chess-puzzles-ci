import '../models/puzzle.dart';

/// Встроенный набор задач.
///
/// Все позиции и решения проверены: первый ход решения единственный,
/// а ответ соперника в задачах на мат в 2 хода вынужденный.
const List<Puzzle> puzzles = [
  Puzzle(
    id: 1,
    title: 'Мат по последней горизонтали',
    fen: '6k1/5ppp/8/8/8/8/5PPP/3R2K1 w - - 0 1',
    solution: ['d1d8'],
    rating: 600,
  ),
  Puzzle(
    id: 2,
    title: 'Детский мат',
    fen: 'r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4',
    solution: ['h5f7'],
    rating: 500,
  ),
  Puzzle(
    id: 3,
    title: 'Дурацкий мат',
    fen: 'rnbqkbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP2P/RNBQKBNR b KQkq - 0 2',
    solution: ['d8h4'],
    rating: 500,
  ),
  Puzzle(
    id: 4,
    title: 'Превращение пешки',
    fen: '7k/4P3/6K1/8/8/8/8/8 w - - 0 1',
    solution: ['e7e8q'],
    rating: 700,
  ),
  Puzzle(
    id: 5,
    title: 'Сдвоенные ладьи',
    fen: 'r5k1/5ppp/8/8/8/8/3R1PPP/3R2K1 w - - 0 1',
    solution: ['d2d8', 'a8d8', 'd1d8'],
    rating: 900,
  ),
  Puzzle(
    id: 6,
    title: 'Спёртый мат',
    fen: '5r1k/6pp/7N/3Q4/8/8/6PP/6K1 w - - 0 1',
    solution: ['d5g8', 'f8g8', 'h6f7'],
    rating: 1200,
  ),
];
