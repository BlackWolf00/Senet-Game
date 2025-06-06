import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/online_game_screen.dart';

class GameLobbyPage extends StatelessWidget {
  final String gameId;

  const GameLobbyPage({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    final gameRef = FirebaseFirestore.instance.collection('games').doc(gameId);
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text('Lobby - ID: $gameId')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: gameRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) {
            return const Center(child: Text('Partita non trovata.'));
          }

          final player1 = data['player1'];
          final player2 = data['player2'];
          final players =
              [
                player1,
                player2,
              ].where((p) => p != null).cast<String>().toList();

          if (currentUser != null &&
              currentUser.uid != player1 &&
              player2 == null) {
            gameRef.update({'player2': currentUser.uid});
          }

          if (players.length == 2) {
            final localPlayerNumber = (currentUser?.uid == player1) ? 1 : 2;
            Future.microtask(() {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => OnlineGameScreen(
                        gameId: gameId,
                        localPlayerNumber: localPlayerNumber,
                      ),
                ),
              );
            });
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('In attesa di un avversario...'),
                const SizedBox(height: 20),
                Text('Giocatori nella stanza: ${players.length}/2'),
                // ...players.map((uid) => Text('Giocatore: $uid')).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}
