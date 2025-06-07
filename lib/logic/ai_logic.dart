import 'dart:math';
import './game_logic.dart';
import './ai_logic_move_calculation.dart';
import '../utils/ai_difficulty.dart';

int selectAIMove(validMoves, aiDifficulty, diceRoll, board, currentPlayer) {
  switch (aiDifficulty) {
    case AIDifficulty.easy:
      return validMoves[Random().nextInt(validMoves.length)];

    case AIDifficulty.medium:
      return validMoves.firstWhere(
            (i) => calculateNewPosition(i, diceRoll) == 30,
        orElse: () => validMoves[Random().nextInt(validMoves.length)],
      );

    case AIDifficulty.hard:
      return bestMove(validMoves, board, currentPlayer, diceRoll);

    case AIDifficulty.extreme:
      return bestMoveConsideringOpponent(validMoves, board, currentPlayer, diceRoll);
  }

  return validMoves.first;
}
