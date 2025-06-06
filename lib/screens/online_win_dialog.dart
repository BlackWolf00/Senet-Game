import 'package:flutter/material.dart';
import '../multiplayer/firebase_game_service.dart';
import '../multiplayer/game_lobby_page.dart';

void showOnlineWinDialog(BuildContext context, int winningPlayer) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("🎉 Vittoria!"),
        content: Text("Il Giocatore $winningPlayer ha vinto la partita."),
        actions: [
          /*TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final gameId = await createOnlineGame();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GameLobbyPage(gameId: gameId),
                ),
              );
            },
            child: Text("Crea nuova partita"),
          ),*/
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
