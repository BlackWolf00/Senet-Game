import 'package:flutter_test/flutter_test.dart';
import 'package:senet_app/logic/game_logic.dart';

/*void main() {
  test('Nessuna mossa possibile quando la board è vuota', () {
    final game = GameLogic();
    game.board = List.filled(30, null);
    game.currentPlayer = 1;
    game.diceRoll = 2;

    expect(game.hasPossibleMove(), isFalse);
  });

  test('Mossa possibile quando un pezzo può avanzare in una cella vuota', () {
    final game = GameLogic();
    game.board = List.filled(30, null);
    game.board[5] = 1;
    game.currentPlayer = 1;
    game.diceRoll = 3;

    expect(game.hasPossibleMove(), isTrue);
  });

  test('Mossa possibile quando un pezzo può avanzare in una cella vuota saltando un pezzo avversario', () {
    final game = GameLogic();
    game.board = List.filled(30, null);
    game.board[5] = 1;
    game.board[6] = 2;
    game.currentPlayer = 1;
    game.diceRoll = 3;

    expect(game.hasPossibleMove(), isTrue);
  });

  test('Mossa possibile quando un pezzo può avanzare in una cella non vuota', () {
    final game = GameLogic();
    game.board = List.filled(30, null);
    game.board[5] = 1;
    game.board[8] = 2;
    game.currentPlayer = 1;
    game.diceRoll = 3;

    expect(game.hasPossibleMove(), isTrue);
  });

  test('Mossa bloccata da tre pezzi su stessa riga', () {
    final game = GameLogic();
    game.board = List.filled(30, null);
    game.board[7] = 2;
    game.board[8] = 2;
    game.board[9] = 2;
    game.board[6] = 1;
    game.currentPlayer = 1;
    game.diceRoll = 5;

    expect(game.hasPossibleMove(), isFalse);
  });

  test('Mossa non bloccata da tre pezzi vicini ma non su stessa riga', () {
    final game = GameLogic();
    game.board = List.filled(30, null);
    game.board[8] = 2;
    game.board[9] = 2;
    game.board[10] = 2;
    game.board[6] = 1;
    game.currentPlayer = 1;
    game.diceRoll = 5;

    expect(game.hasPossibleMove(), isTrue);
  });

  test('Mossa possibile se può scambiare con un avversario non protetto', () {
    final game = GameLogic();
    game.board = List.filled(30, null);
    game.board[5] = 1;
    game.board[8] = 2;
    game.currentPlayer = 1;
    game.diceRoll = 3;

    expect(game.hasPossibleMove(), isTrue);
  });

  test('Mossa bloccata se l’avversario è protetto', () {
    final game = GameLogic();
    game.board = List.filled(30, null);
    game.board[5] = 1;
    game.board[8] = 2;
    game.board[9] = 2;
    game.currentPlayer = 1;
    game.diceRoll = 3;

    expect(game.hasPossibleMove(), isFalse);
  });
}*/
