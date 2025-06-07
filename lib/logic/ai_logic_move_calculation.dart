import 'dart:math';
import './game_logic.dart';

int bestMove(validMoves, board, currentPlayer, diceRoll) {
  int best = validMoves.first;
  int bestScore = -999;
  for (int i in validMoves) {
    int score = evaluateMove(i, board, currentPlayer, diceRoll);
    if (score > bestScore) {
      best = i;
      bestScore = score;
    }
  }
  return best;
}

int bestMoveConsideringOpponent(validMoves, board, currentPlayer, diceRoll) {
  int best = validMoves.first;
  int bestScore = -999;

  for (int myMove in validMoves) {
    // Simula la tua mossa
    List<int?> simulatedBoard = List.from(board);
    int newPos = calculateNewPosition(myMove, diceRoll);
    simulatedBoard[newPos] = currentPlayer;
    simulatedBoard[myMove] = 0;

    // Simula il turno dell'avversario
    int opponent = currentPlayer == 1 ? 2 : 1;
    List<int> opponentMoves = getValidMoves(
      simulatedBoard,
      diceRoll,
      currentPlayer,
    );

    int opponentBestScore =
        opponentMoves.isNotEmpty
            ? opponentMoves
                .map((m) => evaluateMove(m, simulatedBoard, opponent, diceRoll))
                .reduce(max)
            : 0;

    // Il tuo punteggio = tua mossa - migliore risposta nemico
    int myScore =
        evaluateMove(myMove, board, currentPlayer, diceRoll) -
        opponentBestScore;

    if (myScore > bestScore) {
      best = myMove;
      bestScore = myScore;
    }
  }
  return best;
}
