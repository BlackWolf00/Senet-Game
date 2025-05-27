import 'game_logic.dart';
import 'game_ui.dart';
import 'winDialog.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(SenetApp());
}

class SenetApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: MainMenu());
  }
}

class MainMenu extends StatefulWidget {
  @override
  _MainMenuState createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  AIDifficulty selectedDifficulty = AIDifficulty.easy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Senet - Menu')),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/sfondo.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton<AIDifficulty>(
                value: selectedDifficulty,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedDifficulty = value;
                    });
                  }
                },
                items:
                    AIDifficulty.values.map((AIDifficulty difficulty) {
                      return DropdownMenuItem<AIDifficulty>(
                        value: difficulty,
                        child: Text(difficulty.name.toUpperCase()),
                      );
                    }).toList(),
              ),
              SizedBox(height: 20),
              _buildModeButton('Gioca contro l\'IA', true),
              _buildModeButton('Multiplayer Locale', false),
              ElevatedButton(
                onPressed: () {
                  // TODO: implementare multiplayer online
                },
                child: Text('Multiplayer Online'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton(String label, bool vsAI) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GameScreen(
              vsAI: vsAI,
              aiDifficulty: selectedDifficulty,
            ),
          ),
        );
      },
      child: Text(label),
    );
  }
}

enum AIDifficulty { easy, medium, hard }

class GameScreen extends StatefulWidget {
  final bool vsAI;
  final AIDifficulty aiDifficulty;

  GameScreen({required this.vsAI, required this.aiDifficulty});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  List<int?> board = List.filled(30, null);
  int currentPlayer = 1;
  int? selectedPiece;
  int? diceRoll;
  bool canRollDice = true;
  int player1Score = 0;
  int player2Score = 0;

  @override
  void initState() {
    super.initState();
    initializeBoard(board);
  }

  void resetGame() {
    setState(() {
      board = List.filled(30, null);
      diceRoll = null;
      canRollDice = true;
      selectedPiece = null;
      currentPlayer = 1;
      player1Score = 0;
      player2Score = 0;
      initializeBoard(board);
    });
  }

  void rollDice() {
    if (!canRollDice) return;
    int count = List.generate(4, (_) => Random().nextBool() ? 1 : 0).reduce((a, b) => a + b);
    setState(() {
      diceRoll = (count == 0) ? 5 : count;
      canRollDice = false;
    });
    //controllo eventuali mosse
    if (!hasPossibleMove(board, currentPlayer, diceRoll)) {
      setState(() {
        diceRoll = null; // Resetta il lancio
        canRollDice = true;
        currentPlayer = (currentPlayer == 1) ? 2 : 1; // Cambia turno
      });
      if (widget.vsAI && currentPlayer == 2) aiPlay();
    }
  }

  void aiPlay() async {
    await Future.delayed(Duration(milliseconds: 800));
    rollDice();
    await Future.delayed(Duration(milliseconds: 800));

    List<int> validMoves = getValidAIMoves(board, diceRoll);
    if (validMoves.isEmpty) return;

    int choice = selectAIMove(validMoves);
    selectedPiece = choice;
    movePiece();
  }

  int selectAIMove(List<int> validMoves) {
    if (widget.aiDifficulty == AIDifficulty.medium) {
      return validMoves.firstWhere(
            (i) => calculateNewPosition(i, diceRoll!) == 30,
        orElse: () => validMoves[Random().nextInt(validMoves.length)],
      );
    }

    if (widget.aiDifficulty == AIDifficulty.hard) {
      int best = validMoves.first;
      int bestScore = -999;
      for (int i in validMoves) {
        int score = evaluateMove(i, board, currentPlayer, diceRoll);
        if (score > bestScore) {
          best = i;
          bestScore = score;
        }
      }
      return best;
    }

    return validMoves.first;
  }

  void selectPiece(int index, board, currentPlayer) {
    if (widget.vsAI && currentPlayer == 2) return;
    if (board[index] == currentPlayer) {
      setState(() {
        selectedPiece = index;
      });
    }
  }

  void movePiece() {
    if (selectedPiece != null && diceRoll != null) {
      int newPosition = calculateNewPosition(selectedPiece!, diceRoll!);

      if (checkHouseOfHappinessRule(selectedPiece!, newPosition) &&
          newPosition == 26) {
        newPosition = findFirstAvailableBackwardPosition(board);
      }

      if (newPosition == 30) {
        if (currentPlayer == 1) {
          player1Score++;
        } else {
          player2Score++;
        }
        setState(() {
          board[selectedPiece!] = null;
          selectedPiece = null;
          diceRoll = null;
          if (player1Score == 5 || player2Score == 5) {
            print("testo");
            print("Giocatore ${player1Score == 5 ? 1 : 2} ha vinto!");
            showWinDialog(context, player1Score == 5 ? 1 : 2, resetGame);
          }
          currentPlayer = (currentPlayer == 1) ? 2 : 1;
          canRollDice = true;
        });
      }

      if (newPosition < 30) {
        int? occupyingPlayer = board[newPosition];
        if ((occupyingPlayer == null &&
                !isBlockedByThreeGroup(selectedPiece!, newPosition, board, currentPlayer) &&
            checkHouseOfHappinessRule(selectedPiece!, newPosition) &&
            canExitFromSpecialHouse(selectedPiece!, diceRoll!)) ||
            (occupyingPlayer != null &&
                occupyingPlayer != currentPlayer &&
                !isProtectedFromSwap(newPosition, board) &&
                !isBlockedByThreeGroup(selectedPiece!, newPosition, board, currentPlayer) &&
                checkHouseOfHappinessRule(selectedPiece!, newPosition) &&
                canExitFromSpecialHouse(selectedPiece!, diceRoll!))) {
          setState(() {
            if (occupyingPlayer != null) {
              if (selectedPiece == 25 && newPosition == 29) {
                int actualPlayer = board[selectedPiece!]!;
                board[26] = occupyingPlayer;
                board[newPosition] = actualPlayer;
                board[selectedPiece!] = null;
                int newPositionByHouseOfWaterRule =
                findFirstAvailableBackwardPosition(board);
                board[26] = null;
                board[newPositionByHouseOfWaterRule] = occupyingPlayer;
              } else {
                int actualPlayer = board[selectedPiece!]!;
                board[selectedPiece!] = occupyingPlayer;
                board[newPosition] = actualPlayer;
              }
            } else {
              board[newPosition] = currentPlayer;
              board[selectedPiece!] = null;
            }
            selectedPiece = null;
            diceRoll = null;
            currentPlayer = (currentPlayer == 1) ? 2 : 1;
            canRollDice = true;
          });
          if (widget.vsAI && currentPlayer == 2) aiPlay();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Senet'),
          actions: [
            IconButton(
              icon: Icon(Icons.home),
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
          child: Column(
            children: [
              Text(
                'Turno del giocatore: ${currentPlayer == 1 ? "Rosso" : "Blu"}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                "Giocatore 1: $player1Score pedine uscite | Giocatore 2: $player2Score pedine uscite",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 10,
                ),
                itemCount: 30,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => selectPiece(index, board, currentPlayer),
                    child: Container(
                      margin: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: getTileColor(index, selectedPiece, diceRoll),
                        border: Border.all(color: Colors.black),
                      ),
                      child: Center(child: getPiece(board[index])),
                    ),
                  );
                },
              ),
              ElevatedButton(
                onPressed: canRollDice ? rollDice : null,
                child: Text('Lancia i bastoncini'),
              ),
              Text('Risultato: ${diceRoll ?? ""}'),
              ElevatedButton(onPressed: movePiece, child: Text('Muovi pezzo')),
              ElevatedButton(
                onPressed: resetGame,
                child: Text("Resetta Partita"),
              ),
            ],
          ),
        ),
    );
  }
}
