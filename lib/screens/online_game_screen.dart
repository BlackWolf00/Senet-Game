import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OnlineGameScreen extends StatefulWidget {
  final String gameId;
  final int localPlayerNumber;

  const OnlineGameScreen({
    required this.gameId,
    required this.localPlayerNumber,
    super.key,
  });

  @override
  State<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends State<OnlineGameScreen> {
  int? selectedPiece;

  Color getTileColor(int index, int? selected, int? diceRoll) {
    if (index == selected) return Colors.yellow;
    return Colors.white;
  }

  Widget getPiece(dynamic value) {
    if (value == null) return const SizedBox.shrink();
    return Icon(
      Icons.circle,
      color: value == 1 ? Colors.blue : Colors.red,
    );
  }

  void selectPieceOnline(int index, List board, int? currentPlayer, DocumentReference gameDoc) async {
    if (currentPlayer != widget.localPlayerNumber) return;
    if (board[index] != widget.localPlayerNumber) return;

    await gameDoc.update({
      'selectedPiece': index,
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameDoc = FirebaseFirestore.instance.collection('games').doc(widget.gameId);

    return StreamBuilder<DocumentSnapshot>(
      stream: gameDoc.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        List<dynamic> board = data['board'];
        int? currentPlayer = data['currentPlayer'];
        int? diceRoll = data['diceRoll'];
        int? winner = data['winner'];
        bool canRollDice = data['canRollDice'] ?? false;
        int? selected = data['selectedPiece'];

        void rollDice() async {
          if (currentPlayer != widget.localPlayerNumber || !canRollDice) return;

          final roll = List.generate(4, (_) => DateTime.now().millisecondsSinceEpoch % 2).reduce((a, b) => a + b);
          final result = roll == 0 ? 5 : roll;

          await gameDoc.update({
            'diceRoll': result,
            'canRollDice': false,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }

        void movePiece(int index) async {
          if (diceRoll == null || currentPlayer != widget.localPlayerNumber) return;

          if (selected == null || board[selected] != widget.localPlayerNumber) return;

          int destination = selected + diceRoll;
          if (destination != index || destination > 29) return;

          List newBoard = List.from(board);

          // Score if reaching the last square
          if (destination == 29) {
            newBoard[selected] = null;
            final scoreKey = widget.localPlayerNumber == 1 ? 'player1Score' : 'player2Score';
            int score = (data[scoreKey] ?? 0) + 1;
            final newWinner = score == 5 ? widget.localPlayerNumber : null;

            await gameDoc.update({
              'board': newBoard,
              scoreKey: score,
              'currentPlayer': 3 - widget.localPlayerNumber,
              'diceRoll': null,
              'canRollDice': true,
              'selectedPiece': null,
              'winner': newWinner,
              'lastUpdated': FieldValue.serverTimestamp(),
            });
            return;
          }

          if (board[destination] == widget.localPlayerNumber) return;

          newBoard[selected] = null;
          newBoard[destination] = widget.localPlayerNumber;

          await gameDoc.update({
            'board': newBoard,
            'currentPlayer': 3 - widget.localPlayerNumber,
            'diceRoll': null,
            'canRollDice': true,
            'selectedPiece': null,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Online Game')),
          body: Column(
            children: [
              Expanded(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 10,
                  ),
                  itemCount: 30,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        if (diceRoll == null) {
                          selectPieceOnline(index, board, currentPlayer, gameDoc);
                        } else {
                          movePiece(index);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: getTileColor(index, selected, diceRoll),
                          border: Border.all(color: Colors.black),
                        ),
                        child: Center(child: getPiece(board[index])),
                      ),
                    );
                  },
                ),
              ),
              if (winner == null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: rollDice,
                      child: const Text("Roll Dice"),
                    ),
                    if (diceRoll != null) Text("  Rolled: $diceRoll")
                  ],
                )
              else
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Player $winner wins!",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                )
            ],
          ),
        );
      },
    );
  }
}
