import 'package:chess_puzzles/data/puzzles.dart';
import 'package:chess_puzzles/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('на главном экране показан список задач', (tester) async {
    await tester.pumpWidget(const ChessPuzzlesApp());

    expect(find.text('Шахматные задачи'), findsOneWidget);
    expect(find.text(puzzles.first.title), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(puzzles.length));
  });

  testWidgets('задачу можно решить ходами на доске', (tester) async {
    await tester.pumpWidget(const ChessPuzzlesApp());

    await tester.tap(find.text(puzzles.first.title));
    await tester.pumpAndSettle();

    expect(find.text('Ход белых. Найдите лучший ход!'), findsOneWidget);

    // Неверный ход: ладья d1–d7.
    await tester.tap(find.byKey(const Key('square-d1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('square-d7')));
    await tester.pump();
    expect(find.text('Неверно, попробуйте ещё раз.'), findsOneWidget);
    expect(find.text('Ошибок: 1'), findsOneWidget);

    // Верный ход: ладья d1–d8, мат.
    await tester.tap(find.byKey(const Key('square-d1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('square-d8')));
    await tester.pump();
    expect(find.text('Задача решена!'), findsOneWidget);
  });

  testWidgets('в задаче на мат в 2 хода соперник отвечает сам', (tester) async {
    await tester.pumpWidget(const ChessPuzzlesApp());
    await tester.tap(find.text('Сдвоенные ладьи'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('square-d2')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('square-d8')));
    await tester.pump();
    expect(find.text('Верно! Соперник ответил, ваш ход.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('square-d1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('square-d8')));
    await tester.pump();
    expect(find.text('Задача решена!'), findsOneWidget);
  });

  testWidgets('в задаче за чёрных доска развёрнута', (tester) async {
    await tester.pumpWidget(const ChessPuzzlesApp());
    await tester.tap(find.text('Дурацкий мат'));
    await tester.pumpAndSettle();

    expect(find.text('Ход чёрных. Найдите лучший ход!'), findsOneWidget);
    // При взгляде со стороны чёрных поле h1 находится левее поля a1.
    expect(
      tester.getTopLeft(find.byKey(const Key('square-h1'))).dx,
      lessThan(tester.getTopLeft(find.byKey(const Key('square-a1'))).dx),
    );

    await tester.tap(find.byKey(const Key('square-d8')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('square-h4')));
    await tester.pump();
    expect(find.text('Задача решена!'), findsOneWidget);
  });
}
