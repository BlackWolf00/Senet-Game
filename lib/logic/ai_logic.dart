import 'dart:math';
import './game_logic.dart';
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
  return validMoves.first;
}
