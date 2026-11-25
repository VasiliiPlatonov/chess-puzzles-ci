import 'package:flutter/material.dart';

import '../models/board.dart';

/// Виджет шахматной доски 8 × 8.
///
/// Родительский виджет должен задать квадратную область,
/// например с помощью AspectRatio.
class ChessBoard extends StatelessWidget {
  const ChessBoard({
    super.key,
    required this.board,
    required this.onSquareTap,
    this.flipped = false,
    this.selectedSquare,
    this.hintSquare,
  });

  /// Отображаемая позиция.
  final Board board;

  /// Вызывается при нажатии на поле; передаётся название поля, например «e4».
  final ValueChanged<String> onSquareTap;

  /// true — доска развёрнута (снизу чёрные фигуры).
  final bool flipped;

  /// Поле с выбранной фигурой.
  final String? selectedSquare;

  /// Поле, подсвеченное подсказкой.
  final String? hintSquare;

  static const Color _lightSquare = Color(0xFFEEEED2);
  static const Color _darkSquare = Color(0xFF769656);
  static const Color _selectedColor = Color(0xFFF6F669);
  static const Color _hintColor = Color(0xFF8BC4F9);

  /// Символы Unicode для фигур. Для обеих сторон берутся «закрашенные»
  /// символы, а цвет фигуры задаётся стилем текста.
  static const Map<String, String> _glyphs = {
    'k': '\u265A',
    'q': '\u265B',
    'r': '\u265C',
    'b': '\u265D',
    'n': '\u265E',
    'p': '\u265F',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var row = 0; row < 8; row++)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var col = 0; col < 8; col++)
                  Expanded(child: _buildSquare(row, col)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSquare(int row, int col) {
    final index = flipped ? 63 - (row * 8 + col) : row * 8 + col;
    final square = Board.squareName(index);
    final piece = board.pieceAt(square);

    final isLight = (index ~/ 8 + index % 8).isEven;
    var color = isLight ? _lightSquare : _darkSquare;
    if (square == hintSquare) {
      color = _hintColor;
    }
    if (square == selectedSquare) {
      color = _selectedColor;
    }

    return GestureDetector(
      key: Key('square-$square'),
      behavior: HitTestBehavior.opaque,
      onTap: () => onSquareTap(square),
      child: Container(
        color: color,
        padding: const EdgeInsets.all(2),
        child: piece == null ? null : _buildPiece(piece),
      ),
    );
  }

  Widget _buildPiece(String piece) {
    final isWhite = Board.isWhitePiece(piece);
    // Селектор варианта U+FE0E просит показать фигуру как текст, а не как эмодзи.
    final glyph = '${_glyphs[piece.toLowerCase()] ?? '?'}\u{FE0E}';
    return FittedBox(
      child: Text(
        glyph,
        style: TextStyle(
          color: isWhite ? Colors.white : Colors.black,
          shadows: [
            Shadow(
              color: isWhite ? Colors.black : Colors.white,
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}
