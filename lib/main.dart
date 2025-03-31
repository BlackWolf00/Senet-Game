import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(SenetApp());
}

class SenetApp extends StatefulWidget {
  const SenetApp({super.key});

  @override
  _SenetAppState createState() => _SenetAppState();
}

class _SenetAppState extends State {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: SenetHome());
  }
}

class SenetHome extends StatefulWidget {
  const SenetHome({super.key}); /*({Key? key}) : super(key: key)*/

  @override
  _SenetHomeState createState() => _SenetHomeState();
}

class _SenetHomeState extends State<SenetHome> {
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
      diceRoll = null; // Resetta il lancio
      currentPlayer = (currentPlayer == 1) ? 2 : 1; // Cambia turno
      canRollDice = true;
    }
  }

  void selectPiece(int index) {
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
                  canExitFromSpecialHouse(selectedPiece!, diceRoll!)) ||
              (occupyingPlayer != null &&
                  occupyingPlayer != currentPlayer &&
                  !isProtectedFromSwap(newPosition) &&
                  !isBlockedByThreeGroup(i, newPosition) &&
                  checkHouseOfHappinessRule(i, newPosition) &&
                  canExitFromSpecialHouse(selectedPiece!, diceRoll!))) {
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
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Senet')),
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
