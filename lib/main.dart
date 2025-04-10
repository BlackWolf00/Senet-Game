import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(SenetApp());
}

class SenetApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainMenu(),
    );
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DropdownButton<AIDifficulty>(
              value: selectedDifficulty,
              onChanged: (AIDifficulty? newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedDifficulty = newValue;
                  });
                }
              },
              items: AIDifficulty.values.map((AIDifficulty difficulty) {
                return DropdownMenuItem<AIDifficulty>(
                  value: difficulty,
                  child: Text(difficulty.toString().split('.').last.toUpperCase()),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GameScreen(vsAI: true, aiDifficulty: selectedDifficulty)),
                );
              },
              child: Text('Gioca contro l\'IA'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GameScreen(vsAI: false, aiDifficulty: selectedDifficulty)),
                );
              },
              child: Text('Multiplayer Locale'),
            ),
            ElevatedButton(
              onPressed: () {},
              child: Text('Multiplayer Online'),
            ),
          ],
        ),
      ),
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
    initializeBoard();
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
      initializeBoard();
    });
  }

  void initializeBoard() {
    // Posiziona le pedine nelle prime 10 caselle, alternate tra i giocatori
    for (int i = 0; i < 10; i++) {
      board[i] = (i % 2 == 0) ? 1 : 2;
    }
    setState(() {});
  }

  void rollDice() {
    if (!canRollDice) return;
    int count = 0;
    Random random = Random();
    for (int i = 0; i < 4; i++) {
      if (random.nextBool()) count++;
    }
    setState(() {
      diceRoll = (count == 0) ? 5 : count;
      canRollDice = false;
    });
    //controllo eventuali mosse
    if (!hasPossibleMove()) {
      setState(() {
      diceRoll = null; // Resetta il lancio
      currentPlayer = (currentPlayer == 1) ? 2 : 1; // Cambia turno
      canRollDice = true;
      });
      if (widget.vsAI && currentPlayer == 2) aiPlay();
    }
  }

  void aiPlay() async {
    await Future.delayed(Duration(seconds: 1));
    rollDice();
    await Future.delayed(Duration(seconds: 1));

    List<int> validMoves = [];
    for (int i = 0; i < board.length; i++) {
      if (board[i] == 2) {
        int newPosition = calculateNewPosition(i, diceRoll!);
        if (newPosition <= 30) {
          int? occupyingPlayer = (newPosition < 30) ? board[newPosition] : null;
          if (occupyingPlayer == null ||
              (occupyingPlayer != currentPlayer && !isProtectedFromSwap(newPosition))) {
            validMoves.add(i);
          }
        }
      }
    }

    if (validMoves.isEmpty) return;

    int chosenPiece = validMoves.first;

    if (widget.aiDifficulty == AIDifficulty.medium) {
      chosenPiece = validMoves.firstWhere(
            (i) => calculateNewPosition(i, diceRoll!) == 30,
        orElse: () => validMoves.firstWhere(
              (i) {
            int newPos = calculateNewPosition(i, diceRoll!);
            int? opp = newPos < 30 ? board[newPos] : null;
            return opp != null && opp != 2 && !isProtectedFromSwap(newPos);
          },
          orElse: () => validMoves[Random().nextInt(validMoves.length)],
        ),
      );
    } else if (widget.aiDifficulty == AIDifficulty.hard) {
      int bestScore = -999;
      for (int i in validMoves) {
        int score = 0;
        int newPos = calculateNewPosition(i, diceRoll!);
        if (newPos == 30) score += 5;
        if (newPos < 30) {
          int? opp = board[newPos];
          if (opp != null && opp != 2 && !isProtectedFromSwap(newPos)) score += 3;
          if (opp == null) score += 1;
          if (opp == 1 && isExposed(newPos)) score -= 2;
        }
        if (score > bestScore) {
          bestScore = score;
          chosenPiece = i;
        }
      }
    }

    selectedPiece = chosenPiece;
    movePiece();
  }

  bool isExposed(int pos) {
    return pos < 29 && board[pos + 1] != 2 && board[pos + 2] != 2;
  }

  void selectPiece(int index) {
    if (widget.vsAI && currentPlayer == 2) return;
    if (board[index] == currentPlayer) {
      setState(() {
        selectedPiece = index;
      });
    }
  }

  bool isBlockedByThreeGroup(int start, int end) {
    int rowSize = 10;
    int minPos = min(start, end);
    int maxPos = max(start, end);

    for (int pos = minPos; pos <= maxPos; pos++) {
      int row = pos ~/ rowSize;
      int col = pos % rowSize;

      for (int i = max(0, col - 2); i <= min(rowSize - 3, col); i++) {
        if ((board[row * rowSize + i] != currentPlayer &&
                board[row * rowSize + i] != null) &&
            (board[row * rowSize + i + 1] != currentPlayer &&
                board[row * rowSize + i + 1] != null) &&
            (board[row * rowSize + i + 2] != currentPlayer &&
                board[row * rowSize + i + 2] != null)) {
          if (pos >= i && pos <= i + 2) {
            return true;
          }
        }
      }
    }
    return false;
  }

  bool isProtectedBySpecialHouse(index) {
    if (index == 15) return true;
    if (index == 25) return true;
    if (index == 27) return true;
    if (index == 28) return true;
    return false;
  }

  bool isInsideHouseWithMovementLimitation(int index) {
    if (index == 27) return true;
    if (index == 28) return true;
    if (index == 29) return true;
    return false;
  }

  bool canExitFromSpecialHouse(int index, int roll) {
    if (isInsideHouseWithMovementLimitation(index)) {
      if (index == 27 && roll == 3) return true;
      if (index == 28 && roll == 2) return true;
      if (index == 29 && roll == 1) return true;
      return false;
    }
    return true;
  }

  bool isProtectedFromSwap(int index) {
    int? player = board[index];
    if (player == null) return false;
    if (index == 29) return false;

    // Controllo se il pezzo fa parte di una coppia protetta
    if (index > 0 && board[index - 1] == player) return true;
    if (index < board.length - 1 && board[index + 1] == player) return true;
    return isProtectedBySpecialHouse(index);
  }

  int calculateNewPosition(int position, int roll) {
    int row = position ~/ 10;
    int col = position % 10;

    if (row == 1) {
      // Seconda riga, movimento da destra a sinistra
      col -= roll;
      if (col < 0) {
        int overflow = -col - 1;
        return 20 + overflow;
      }
    } else {
      // Prima e terza riga, movimento da sinistra a destra
      col += roll;
      if (col >= 10) {
        int overflow = col - 10;
        if ((row + 1) * 20 - 1 - overflow > 30) {
          return row * 10 + col;
        }
        return (row + 1) * 20 - 1 - overflow;
      }
    }
    return row * 10 + col;
  }

  bool hasPossibleMove() {
    for (int i = 0; i < board.length; i++) {
      if (board[i] == currentPlayer) {
        int newPosition = calculateNewPosition(i, diceRoll!);
        if (newPosition == 30) {
          return true;
        }
        if (newPosition < 30) {
          int? occupyingPlayer = board[newPosition];
          if ((occupyingPlayer == null &&
                  !isBlockedByThreeGroup(i, newPosition) &&
                  checkHouseOfHappinessRule(i, newPosition) &&
                  canExitFromSpecialHouse(i, diceRoll!)) ||
              (occupyingPlayer != null &&
                  occupyingPlayer != currentPlayer &&
                  !isProtectedFromSwap(newPosition) &&
                  !isBlockedByThreeGroup(i, newPosition) &&
                  checkHouseOfHappinessRule(i, newPosition) &&
                  canExitFromSpecialHouse(i, diceRoll!))) {
            return true; // Se almeno una mossa è valida, il turno non è bloccato
          }
        }
      }
    }
    return false; // Nessuna mossa valida, il turno viene passato
  }

  bool checkHouseOfHappinessRule(index, newPosition) {
    if (index < 25 && newPosition > 25) return false;
    return true;
  }

  int findFirstAvailableBackwardPosition() {
    List<int> priorityPositions = [15, 16, 17, 18, 19, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0];

    for (int pos in priorityPositions) {
      if (board[pos] == null) {
        return pos;
      }
    }

    return 26; // Se nessuna posizione è disponibile, rimane nella casella 26, impossibile
  }

  void movePiece() {
    if (selectedPiece != null && diceRoll != null) {
      int newPosition = calculateNewPosition(selectedPiece!, diceRoll!);

      if (checkHouseOfHappinessRule(selectedPiece!, newPosition) && newPosition == 26) {
        newPosition = findFirstAvailableBackwardPosition();
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
            showWinDialog(context, player1Score == 5 ? 1 : 2);
          }
          currentPlayer = (currentPlayer == 1) ? 2 : 1;
          canRollDice = true;
        });
      }

      if (newPosition < 30) {
        int? occupyingPlayer = board[newPosition];
        if ((occupyingPlayer == null &&
                !isBlockedByThreeGroup(selectedPiece!, newPosition) &&
                checkHouseOfHappinessRule(selectedPiece!, newPosition) &&
                canExitFromSpecialHouse(selectedPiece!, diceRoll!)) ||
            (occupyingPlayer != null &&
                occupyingPlayer != currentPlayer &&
                !isProtectedFromSwap(newPosition) &&
                !isBlockedByThreeGroup(selectedPiece!, newPosition) &&
                checkHouseOfHappinessRule(selectedPiece!, newPosition) &&
                canExitFromSpecialHouse(selectedPiece!, diceRoll!))) {
          setState(() {
            if (occupyingPlayer != null) {
              if (selectedPiece == 25 && newPosition == 29) {
                int actualPlayer = board[selectedPiece!]!;
                board[26] = occupyingPlayer;
                board[newPosition] = actualPlayer;
                board[selectedPiece!] = null;
                int newPositionByHouseOfWaterRule = findFirstAvailableBackwardPosition();
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

  Color getTileColor(int index) {
    if (index == selectedPiece)
      return Colors.redAccent; // Evidenzia la pedina selezionata
    if (selectedPiece != null && diceRoll != null) {
      int newPosition = calculateNewPosition(selectedPiece!, diceRoll!);
      if (index == newPosition)
        return Colors.deepPurpleAccent; // Evidenzia dove andrà la pedina
    }
    if (index == 15) return Colors.green;
    if (index == 25) return Colors.yellow;
    if (index == 26) return Colors.blue;
    if (index >= 27) return Colors.orange;
    return Colors.brown.shade300;
  }

  Widget getPiece(int? player) {
    if (player == 1) {
      return Icon(Icons.circle, color: Colors.red, size: 24);
    } else if (player == 2) {
      return Icon(Icons.square, color: Colors.black, size: 24);
    } else {
      return SizedBox.shrink();
    }
  }

  void showWinDialog(BuildContext context, int player) {
    showDialog(
      context: context,
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
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: Text('Senet'), actions: [
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () {
              Navigator.pop(context);
            },
          )
        ]),
        body: Column(
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
                  onTap: () => selectPiece(index),
                  child: Container(
                    margin: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: getTileColor(index),
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
