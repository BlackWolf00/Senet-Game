import 'package:flutter_test/flutter_test.dart';

void main() {
    test('findFirstAvailableBackwardPosition should return the first available position in order', () {
      List<int?> board = List.filled(30, null); // Simula il tabellone vuoto

      // Caso base: prima casella libera è la 15
      expect(findFirstAvailableBackwardPosition(board), equals(15));

      // Se la 15 è occupata, dovrebbe restituire la 16
      board[15] = 1;
      expect(findFirstAvailableBackwardPosition(board), equals(16));

      // Se 15-19 sono occupate, dovrebbe restituire la 9
      board[16] = 1;
      board[17] = 1;
      board[18] = 1;
      board[19] = 1;
      expect(findFirstAvailableBackwardPosition(board), equals(9));

      // Se tutte le priorità sono occupate, deve restituire la prima disponibile
      board[9] = 1;
      board[8] = 1;
      board[7] = 1;
      board[6] = 1;
      expect(findFirstAvailableBackwardPosition(board), equals(5));

      // Se nessuna posizione è libera, dovrebbe restituire 26
      for (int i in [5, 4, 3, 2, 1, 0]) {
        board[i] = 1;
      }
      expect(findFirstAvailableBackwardPosition(board), equals(26));
    });
}

int findFirstAvailableBackwardPosition(List<int?> board) {
  List<int> priorityPositions = [15, 16, 17, 18, 19, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0];

  for (int pos in priorityPositions) {
    if (board[pos] == null) {
      return pos;
    }
  }

  return 26;
}
