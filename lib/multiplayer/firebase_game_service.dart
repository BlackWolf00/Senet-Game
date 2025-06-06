import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../ui/game_ui.dart';

Future<String> createOnlineGame() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) throw Exception("Utente non autenticato");

  List<int?> board = List.filled(30, null);
  for (int i = 0; i < 10; i++) {
    board[i] = (i % 2 == 0) ? 1 : 2;
  }

  final newGame = {
    'player1': uid,
    'player2': null,
    'board': board,
    'currentPlayer': 1,
    'diceRoll': null,
    'player1Score': 0,
    'player2Score': 0,
    'status': 'waiting',
    'canRollDice': true,
    'lastMove': null,
    'createdAt': FieldValue.serverTimestamp(),
    'lastUpdated': FieldValue.serverTimestamp(),
  };

  final gameDoc = await FirebaseFirestore.instance
      .collection('games')
      .add(newGame);
  return gameDoc.id;
}
