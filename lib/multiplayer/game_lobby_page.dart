import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../screens/online_game_screen.dart';

class GameLobbyPage extends StatelessWidget {
  final String gameId;

  const GameLobbyPage({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    final gameRef = FirebaseFirestore.instance.collection('games').doc(gameId);
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Lobby - ID: $gameId'),
        actions: [
          IconButton(
            icon: Icon(Icons.copy),
            tooltip: 'Copy Game ID',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: gameId));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Game ID copied to clipboard')),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.share),
            tooltip: 'Share Game ID',
            onPressed: () {
              Share.share(
                'Join my Senet game! Game ID: $gameId',
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/sfondo.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: StreamBuilder<DocumentSnapshot>(
          stream: gameRef.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!.data() as Map<String, dynamic>?;
            if (data == null) {
              return const Center(child: Text('Game not found.'));
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  constraints: BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people, size: 48, color: Colors.white),
                      const SizedBox(height: 16),
                      Text(
                        'Waiting for an opponent...',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Players in the room: ${players.length}/2',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      ...players.map(
                        (uid) => Text(
                          'Player: $uid',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      const SizedBox(height: 32),
                      CircularProgressIndicator(color: Colors.white),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
