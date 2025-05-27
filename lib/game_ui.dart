import 'game_logic.dart';
import 'package:flutter/material.dart';

Color getTileColor(int index, selectedPiece, diceRoll) {
  if (index == selectedPiece)
    return Colors.redAccent; // Evidenzia la pedina selezionata
  if (selectedPiece != null && diceRoll != null) {
    int newPosition = calculateNewPosition(selectedPiece!, diceRoll!);
    if (index == newPosition)
      return Colors.deepPurpleAccent; // Evidenzia dove andrà la pedina
  }
  if (index == 15) return Colors.green;
  if (index == 25) return Colors.yellow;
  if (index == 26) return Colors.blue;
  if (index >= 27) return Colors.orange;
  return Colors.brown.shade300;
}

Widget getPiece(int? player) {
  if (player == 1) {
    return Icon(Icons.circle, color: Colors.red, size: 24);
  } else if (player == 2) {
    return Icon(Icons.square, color: Colors.black, size: 24);
  } else {
    return SizedBox.shrink();
  }
}