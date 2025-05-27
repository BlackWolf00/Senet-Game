import 'dart:math';

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
        if ((row + 1) * 20 - 1 - overflow > 30) {
          return row * 10 + col;
        }
        return (row + 1) * 20 - 1 - overflow;
      }
    }
    return row * 10 + col;
  }

  bool checkHouseOfHappinessRule(index, newPosition) {
    if (index < 25 && newPosition > 25) return false;
    return true;
  }

  int findFirstAvailableBackwardPosition(board) {
    List<int> priorityPositions = [
      15,
      16,
      17,
      18,
      19,
      9,
      8,
      7,
      6,
      5,
      4,
      3,
      2,
      1,
      0,
    ];

    for (int pos in priorityPositions) {
      if (board[pos] == null) {
        return pos;
      }
    }

    return 26; // Se nessuna posizione è disponibile, rimane nella casella 26, impossibile
  }

  bool isProtectedBySpecialHouse(index) {
    if (index == 15) return true;
    if (index == 25) return true;
    if (index == 27) return true;
    if (index == 28) return true;
    return false;
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

  bool isProtectedFromSwap(int index, board) {
    int? player = board[index];
    if (player == null) return false;
    if (index == 29) return false;

    // Controllo se il pezzo fa parte di una coppia protetta
    if (index > 0 && board[index - 1] == player) return true;
    if (index < board.length - 1 && board[index + 1] == player) return true;
    return isProtectedBySpecialHouse(index);
  }

  // TODO: DA ELIMINARE
  bool isExposed(int pos, board) {
    return pos < 29 && board[pos + 1] != 2 && board[pos + 2] != 2;
  }

  bool hasPossibleMove(board, currentPlayer, diceRoll) {
    for (int i = 0; i < board.length; i++) {
      if (board[i] == currentPlayer) {
        int newPosition = calculateNewPosition(i, diceRoll!);
        if (newPosition == 30) {
          return true;
        }
        if (newPosition < 30) {
          int? occupyingPlayer = board[newPosition];
          if ((occupyingPlayer == null &&
                  !isBlockedByThreeGroup(i, newPosition, board, currentPlayer) &&
                  checkHouseOfHappinessRule(i, newPosition) &&
                  canExitFromSpecialHouse(i, diceRoll!)) ||
              (occupyingPlayer != null &&
                  occupyingPlayer != currentPlayer &&
                  !isProtectedFromSwap(newPosition, board) &&
                  !isBlockedByThreeGroup(i, newPosition, board, currentPlayer) &&
                  checkHouseOfHappinessRule(i, newPosition) &&
                  canExitFromSpecialHouse(i, diceRoll!))) {
            return true; // Se almeno una mossa è valida, il turno non è bloccato
          }
        }
      }
    }
    return false; // Nessuna mossa valida, il turno viene passato
  }

  void selectPiece(int index, board, currentPlayer) {
    if (board[index] == currentPlayer) {}
  }

  bool isBlockedByThreeGroup(int start, int end, board, currentPlayer) {
    int rowSize = 10;
    int minPos = min(start, end);
    int maxPos = max(start, end);

    for (int pos = minPos; pos <= maxPos; pos++) {
      int row = pos ~/ rowSize;
      int col = pos % rowSize;

      for (int i = max(0, col - 2); i <= min(rowSize - 3, col); i++) {
        if ((board[row * rowSize + i] != currentPlayer &&
            board[row * rowSize + i] != null) &&
            (board[row * rowSize + i + 1] != currentPlayer &&
                board[row * rowSize + i + 1] != null) &&
            (board[row * rowSize + i + 2] != currentPlayer &&
                board[row * rowSize + i + 2] != null)) {
          if (pos >= i && pos <= i + 2) {
            return true;
          }
        }
      }
    }
    return false;
  }

  List<int> getValidAIMoves(board, diceRoll) {
    List<int> valid = [];
    for (int i = 0; i < board.length; i++) {
      if (board[i] == 2) {
        int dest = calculateNewPosition(i, diceRoll!);
        if (dest <= 30) {
          int? target = (dest < 30) ? board[dest] : null;
          if (target == null || (target != 2 && !isProtectedFromSwap(dest, board))) {
            valid.add(i);
          }
        }
      }
    }
    return valid;
  }

  int evaluateMove(int from, board, currentPlayer, diceRoll) {
    int to = calculateNewPosition(from, diceRoll!);
    int score = 0;
    if (to == 30) score += 5;
    if (to < 30) {
      int? target = board[to];
      if (target == null) score += 1;
      if (target != null && target != currentPlayer) score += 3;
    }
    return score;
  }