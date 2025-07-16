import 'package:flutter/material.dart';

void showWinDialog(BuildContext context, int player, VoidCallback resetGame) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Player $player won! 🎉"),
        content: Text("Do you want to play again?"),
        actions: [
          TextButton(
            onPressed: () {
              resetGame();
              Navigator.of(context).pop();
            },
            child: Text("Replay"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text('Back to menu'),
          ),
        ],
      );
    },
  );
}
