import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(SenetApp());
}

class SenetApp extends StatefulWidget {
  @override
  _SenetAppState createState() => _SenetAppState();
}

class _SenetAppState extends State<SenetApp> {
  List<int?> board = List.filled(30, null);
  int currentPlayer = 1;
  int? selectedPiece;
  int? diceRoll;
  bool canRollDice = true;

  @override
  void initState() {
    super.initState();
    initializeBoard();
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
        if ((board[row * rowSize + i] != currentPlayer && board[row * rowSize + i] != null) &&
            (board[row * rowSize + i + 1] != currentPlayer && board[row * rowSize + i + 1] != null) &&
            (board[row * rowSize + i + 2] != currentPlayer && board[row * rowSize + i + 2] != null)) {
          if (pos >= i && pos <= i + 2) {
            return true;
          }
        }
      }
    }
    return false;
  }

  bool isProtectedFromSwap(int index) {
    int? player = board[index];
    if (player == null) return false;

    // Controllo se il pezzo fa parte di una coppia protetta
    if (index > 0 && board[index - 1] == player) return true;
    if (index < board.length - 1 && board[index + 1] == player) return true;

    return false;
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
        return (row + 1) * 20 - 1 - overflow;
      }
    }
    return row * 10 + col;
  }

  bool hasPossibleMove() {
    for (int i = 0; i < board.length; i++) {
      if (board[i] == currentPlayer) {
        int newPosition = calculateNewPosition(i, diceRoll!);
        if (newPosition < 30) {
          int? occupyingPlayer = board[newPosition];
          if ((occupyingPlayer == null && !isBlockedByThreeGroup(i, newPosition)) ||
              (occupyingPlayer != null && occupyingPlayer != currentPlayer && !isProtectedFromSwap(newPosition) && !isBlockedByThreeGroup(i, newPosition))) {
            return true; // Se almeno una mossa è valida, il turno non è bloccato
          }
        }
      }
    }
    return false; // Nessuna mossa valida, il turno viene passato
  }

  void movePiece() {
    if (selectedPiece != null && diceRoll != null) {
      int newPosition = calculateNewPosition(selectedPiece!, diceRoll!);

      if (newPosition < 30) {
        int? occupyingPlayer = board[newPosition];
        if ((occupyingPlayer == null && !isBlockedByThreeGroup(selectedPiece!, newPosition)) ||
            (occupyingPlayer != null && occupyingPlayer != currentPlayer && !isProtectedFromSwap(newPosition) && !isBlockedByThreeGroup(selectedPiece!, newPosition))) {
          setState(() {
            if (occupyingPlayer != null) {
              int previousPlayer = board[selectedPiece!]!;
              board[selectedPiece!] = occupyingPlayer;
              board[newPosition] = previousPlayer;
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
    if (index == selectedPiece) return Colors.redAccent; // Evidenzia la pedina selezionata
    if (selectedPiece != null && diceRoll != null) {
      int newPosition = calculateNewPosition(selectedPiece!, diceRoll!);
      if (index ==  newPosition)
        return Colors.deepPurpleAccent; // Evidenzia dove andrà la pedina
    }
    if (index == 14) return Colors.green;
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
            ElevatedButton(
              onPressed: movePiece,
              child: Text('Muovi pezzo'),
            ),
          ],
        ),
      ),
    );
  }
}
