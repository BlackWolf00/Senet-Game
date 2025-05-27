import 'package:flutter_test/flutter_test.dart';
import 'package:senet_app/logic/game_logic.dart';

void main() {
  test('Verifica se un pezzo può uscire da una casa speciale', () {
    final game = GameLogic();

    expect(game.canExitFromSpecialHouse(27, 3), isTrue); // Caso valido
    expect(game.canExitFromSpecialHouse(28, 2), isTrue); // Caso valido
    expect(game.canExitFromSpecialHouse(29, 1), isTrue); // Caso valido

    expect(game.canExitFromSpecialHouse(27, 2), isFalse); // Roll sbagliato
    expect(game.canExitFromSpecialHouse(28, 3), isFalse); // Roll sbagliato
    expect(game.canExitFromSpecialHouse(29, 2), isFalse); // Roll sbagliato

    expect(game.canExitFromSpecialHouse(25, 3), isTrue); // Casa sbagliata
    expect(game.canExitFromSpecialHouse(13, 2), isTrue); // Casa sbagliata
    expect(game.canExitFromSpecialHouse(15, 5), isTrue); // Casa sbagliata
  });

}