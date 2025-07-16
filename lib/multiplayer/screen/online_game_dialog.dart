import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../game_lobby_page.dart';
import '../firebase_game_service.dart';

class OnlineGameDialog extends StatefulWidget {
  const OnlineGameDialog({super.key});

  @override
  State<OnlineGameDialog> createState() => _OnlineGameDialogState();
}

class _OnlineGameDialogState extends State<OnlineGameDialog> {
  String gameId = '';
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Online Multiplayer', textAlign: TextAlign.center),
      content:
          isLoading
              ? Center(heightFactor: 1.5, child: CircularProgressIndicator())
              : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      setState(() => isLoading = true);
                      final gameId = await createOnlineGame();
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GameLobbyPage(gameId: gameId),
                        ),
                      );
                    },
                    child: Text('Create new game'),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Game ID',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => gameId = value.trim(),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: /*(gameId.isEmpty) ? null :*/ () async {
                      if (gameId.isNotEmpty) {
                        setState(() => isLoading = true);
                        final gameRef = FirebaseFirestore.instance
                            .collection('games')
                            .doc(gameId);
                        final doc = await gameRef.get();
                        final uid = FirebaseAuth.instance.currentUser?.uid;
                        if (doc.exists && uid != null) {
                          final data = doc.data()!;
                          if (data['player2'] == null &&
                              data['player1'] != uid) {
                            await gameRef.update({
                              'player2': uid,
                              'status': 'active',
                            });
                          }
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GameLobbyPage(gameId: gameId),
                            ),
                          );
                        } else {
                          setState(() => isLoading = true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Match not found or already full.'),
                            ),
                          );
                        }
                      }
                    },
                    child: Text('Join a game'),
                  ),
                ],
              ),
    );
  }
}
