import 'package:flutter/material.dart';

import 'screens/puzzle_list_screen.dart';

void main() {
  runApp(const ChessPuzzlesApp());
}

/// Корневой виджет приложения «Шахматные задачи».
class ChessPuzzlesApp extends StatelessWidget {
  const ChessPuzzlesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Шахматные задачи',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.green),
      home: const PuzzleListScreen(),
    );
  }
}
