import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import '../screens/online_win_dialog.dart';
import '../logic/game_logic.dart';
import '../ui/game_ui.dart';

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
  bool hasShownDialog = false;
  int? _previousPlayer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ValueNotifier<bool> _pulse = ValueNotifier(false);

  void selectPiece(
    int index,
    List board,
    int? currentPlayer,
    DocumentReference gameDoc,
  ) async {
    if (currentPlayer != widget.localPlayerNumber) return;
    if (board[index] != widget.localPlayerNumber) return;

    await gameDoc.update({'selectedPiece': index});
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameDoc = FirebaseFirestore.instance
        .collection('games')
        .doc(widget.gameId);

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
        if (_previousPlayer != null &&
            _previousPlayer != currentPlayer &&
            currentPlayer == widget.localPlayerNumber) {
          _audioPlayer.play(AssetSource('sounds/turn.mp3'));
          _pulse.value = true;
          Future.microtask(() async {
            await _audioPlayer.play(AssetSource('sounds/turn.mp3'));
            _pulse.value = true;
            if (await Vibration.hasVibrator() ?? false) {
              Vibration.vibrate(duration: 100);
            }
          });
        }
        _previousPlayer = currentPlayer;
        if (winner != null && !hasShownDialog) {
          hasShownDialog = true;
          Future.microtask(() {
            showOnlineWinDialog(context, winner);
          });
        }
        bool canRollDice = data['canRollDice'] ?? false;
        int? selected = data['selectedPiece'];
        int player1Score = data['player1Score'] ?? 0;
        int player2Score = data['player2Score'] ?? 0;

        void resetGame() async {
          List<dynamic> newBoard = List.filled(30, null);
          initializeBoard(newBoard);

          await gameDoc.update({
            'board': newBoard,
            'diceRoll': null,
            'canRollDice': true,
            'selectedPiece': null,
            'currentPlayer': 1,
            'player1Score': 0,
            'player2Score': 0,
            'winner': null,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }

        void rollDice() async {
          if (currentPlayer != widget.localPlayerNumber || !canRollDice) return;

          final roll = List.generate(
            4,
            (_) => DateTime.now().millisecondsSinceEpoch % 2,
          ).reduce((a, b) => a + b);
          final result = roll == 0 ? 5 : roll;

          bool possibleMove = hasPossibleMove(board, currentPlayer, result);

          if (!possibleMove) {
            await gameDoc.update({
              'diceRoll': null,
              'canRollDice': true,
              'currentPlayer': currentPlayer == 1 ? 2 : 1,
              'lastUpdated': FieldValue.serverTimestamp(),
            });
          } else {
            await gameDoc.update({
              'diceRoll': result,
              'canRollDice': false,
              'lastUpdated': FieldValue.serverTimestamp(),
            });
          }
        }

        void movePieceOnline() async {
          if (selected == null ||
              diceRoll == null ||
              currentPlayer != widget.localPlayerNumber)
            return;

          int from = selected;
          int to = calculateNewPosition(from, diceRoll);
          List newBoard = List.from(board);

          // Caso speciale: Casa della felicità
          if (checkHouseOfHappinessRule(from, to) && to == 26) {
            to = findFirstAvailableBackwardPosition(newBoard);
          }

          // Se il giocatore arriva alla fine (casella 30)
          if (to == 30) {
            final scoreKey =
                widget.localPlayerNumber == 1 ? 'player1Score' : 'player2Score';
            int playerScore = (data[scoreKey] ?? 0) + 1;
            int? winner = playerScore == 5 ? widget.localPlayerNumber : null;

            newBoard[from] = null;

            await gameDoc.update({
              'board': newBoard,
              scoreKey: playerScore,
              'selectedPiece': null,
              'diceRoll': null,
              'currentPlayer': 3 - widget.localPlayerNumber,
              'canRollDice': true,
              'winner': winner,
              'lastUpdated': FieldValue.serverTimestamp(),
            });
            return;
          }

          if (to > 30) return;

          int? occupyingPlayer = newBoard[to];

          bool canMove = false;

          if (occupyingPlayer == null) {
            canMove =
                !isBlockedByThreeGroup(from, to, board, currentPlayer) &&
                checkHouseOfHappinessRule(from, to) &&
                canExitFromSpecialHouse(from, diceRoll);
          } else if (occupyingPlayer != currentPlayer) {
            canMove =
                !isProtectedFromSwap(to, board) &&
                !isBlockedByThreeGroup(from, to, board, currentPlayer) &&
                checkHouseOfHappinessRule(from, to) &&
                canExitFromSpecialHouse(from, diceRoll);
          }

          if (!canMove) return;

          // Movimento con swap o semplice
          if (occupyingPlayer != null) {
            if (from == 25 && to == 29) {
              // Casa dell'acqua: rimbalzo e swap
              int actualPlayer = newBoard[from]!;
              newBoard[from] = null;
              newBoard[to] = actualPlayer;
              newBoard[26] = occupyingPlayer;
              int backPos = findFirstAvailableBackwardPosition(newBoard);
              newBoard[26] = null;
              newBoard[backPos] = occupyingPlayer;
            } else {
              // Swap normale
              int actualPlayer = newBoard[from]!;
              newBoard[from] = occupyingPlayer;
              newBoard[to] = actualPlayer;
            }
          } else {
            // Movimento semplice
            newBoard[to] = currentPlayer;
            newBoard[from] = null;
          }

          await gameDoc.update({
            'board': newBoard,
            'selectedPiece': null,
            'diceRoll': null,
            'currentPlayer': 3 - widget.localPlayerNumber,
            'canRollDice': true,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Senet - ID partita: ${widget.gameId}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.home),
                onPressed: () {
                  Navigator.pop(context);
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
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Turno del giocatore: ${currentPlayer == 1 ? "Rosso" : "Nero"}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Giocatore 1: $player1Score pedine uscite | Giocatore 2: $player2Score pedine uscite",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      ValueListenableBuilder<bool>(
                        valueListenable: _pulse,
                        builder: (context, pulse, child) {
                          return AnimatedScale(
                            scale: pulse ? 1.1 : 1.0,
                            duration: const Duration(milliseconds: 250),
                            onEnd: () => _pulse.value = false,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 12),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (currentPlayer == widget.localPlayerNumber)
                                        ? Colors.green.withOpacity(0.7)
                                        : Colors.orange.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    currentPlayer == widget.localPlayerNumber
                                        ? Icons.check_circle
                                        : Icons.hourglass_top,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    currentPlayer == widget.localPlayerNumber
                                        ? "È il tuo turno!"
                                        : "In attesa dell’avversario...",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 10,
                        ),
                        itemCount: 30,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap:
                                () => selectPiece(
                                  index,
                                  board,
                                  currentPlayer,
                                  gameDoc,
                                ),
                            child: Container(
                              margin: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: getTileColorOnline(
                                  index,
                                  selected,
                                  diceRoll,
                                  currentPlayer,
                                  widget.localPlayerNumber,
                                ),
                                border: Border.all(color: Colors.white),
                              ),
                              child: Center(child: getPiece(board[index])),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed:
                            (canRollDice &&
                                    currentPlayer == widget.localPlayerNumber)
                                ? rollDice
                                : null,
                        child: Text('Lancia i bastoncini'),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Risultato: ${diceRoll ?? ""}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed:
                            (selected != null &&
                                    currentPlayer == widget.localPlayerNumber)
                                ? () => movePieceOnline()
                                : null,
                        child: Text('Muovi pezzo'),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: resetGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                        child: Text("Resetta Partita"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
