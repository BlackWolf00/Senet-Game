import 'dart:math';

class GameLogic {
  List<int?> board = List.filled(30, null);
  int currentPlayer = 1;
  int? selectedPiece;
  int? diceRoll;
  bool canRollDice = true;

  GameLogic() {
    initializeBoard();
  }

  void initializeBoard() {
    for (int i = 0; i < 10; i++) {
      board[i] = (i % 2 == 0) ? 1 : 2;
    }
  }

  int calculateNewPosition(int position, int roll) {
    int row = position ~/ 10;
    int col = position % 10;

    if (row == 1) {
      // Seconda riga, movimento da destra a sinistra
      col -= roll;
      if (col < 0) {
        int overflow = -col - 1;
        return 20 + overflow;
      }
    } else {
      // Prima e terza riga, movimento da sinistra a destra
      col += roll;
      if (col >= 10) {
        int overflow = col - 10;
        return (row + 1) * 20 - 1 - overflow;
      }
    }
    return row * 10 + col;
  }

  bool isInsideHouseWithMovementLimitation(int index) {
    if (index == 27) return true;
    if (index == 28) return true;
    if (index == 29) return true;
    return false;
  }

  bool canExitFromSpecialHouse(int index, int roll) {
    if (isInsideHouseWithMovementLimitation(index)) {
      if (index == 27 && roll == 3) return true;
      if (index == 28 && roll == 2) return true;
      if (index == 29 && roll == 1) return true;
      return false;
    }
    return true;
  }

  bool hasPossibleMove() {
    for (int i = 0; i < board.length; i++) {
      if (board[i] == currentPlayer) {
        print([board[i], i]);
        int newPosition = calculateNewPosition(i, diceRoll!);
        if (newPosition < 30) {
          int? occupyingPlayer = board[newPosition];
          if ((occupyingPlayer == null && !isBlockedByThreeGroup(i, newPosition)) ||
              (occupyingPlayer != null && occupyingPlayer != currentPlayer && !isProtectedFromSwap(newPosition) && !isBlockedByThreeGroup(i, newPosition))) {
            print([occupyingPlayer, isBlockedByThreeGroup(i, newPosition)]);
            return true; // Se almeno una mossa è valida, il turno non è bloccato
          }
        }
      }
    }
    return false; // Nessuna mossa valida, il turno viene passato
  }

  void rollDice() {
    if (!canRollDice) return;
    int count = 0;
    Random random = Random();
    for (int i = 0; i < 4; i++) {
      if (random.nextBool()) count++;
    }
    //controllo eventuali mosse
    if (!hasPossibleMove()) {
      diceRoll = null; // Resetta il lancio
      currentPlayer = (currentPlayer == 1) ? 2 : 1; // Cambia turno
      canRollDice = true;
    }
  }

  void selectPiece(int index) {
    if (board[index] == currentPlayer) {
    }
  }

  bool isProtectedFromSwap(int index) {
    int? player = board[index];
    if (player == null) return false;

    // Controllo se il pezzo fa parte di una coppia protetta
    if (index > 0 && board[index - 1] == player) return true;
    if (index < board.length - 1 && board[index + 1] == player) return true;

    return false;
  }

  bool isBlockedByThreeGroup(int start, int end) {
    int rowSize = 10;
    int minPos = min(start, end);
    int maxPos = max(start, end);

    for (int pos = minPos; pos <= maxPos; pos++) {
      int row = pos ~/ rowSize;
      int col = pos % rowSize;

      for (int i = max(0, col - 2); i <= min(rowSize - 3, col); i++) {
        print(["dove sono", i]);
        if ((board[row * rowSize + i] != currentPlayer && board[row * rowSize + i] != null) &&
            (board[row * rowSize + i + 1] != currentPlayer && board[row * rowSize + i + 1] != null) &&
            (board[row * rowSize + i + 2] != currentPlayer && board[row * rowSize + i + 2] != null)) {
          if (pos >= i && pos <= i + 2) {
            return true;
          }
        }
      }
    }
    return false;
  }
}
