import 'package:flutter/material.dart';

void showWinDialog(BuildContext context, int player, VoidCallback resetGame) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Giocatore $player ha vinto! 🎉"),
        content: Text("Vuoi rigiocare?"),
        actions: [
          TextButton(
            onPressed: () {
              resetGame();
              Navigator.of(context).pop();
            },
            child: Text("Rigioca"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text('Torna al menu'),
          ),
        ],
      );
    },
  );
}
