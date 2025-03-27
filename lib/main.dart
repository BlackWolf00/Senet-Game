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
    int count = 0;
    Random random = Random();
    for (int i = 0; i < 4; i++) {
      if (random.nextBool()) count++;
    }
    setState(() {
      diceRoll = (count == 0) ? 5 : count;
    });
  }

  void selectPiece(int index) {
    if (board[index] == currentPlayer) {
      setState(() {
        selectedPiece = index;
      });
    }
  }

  void movePiece() {
    if (selectedPiece != null && diceRoll != null) {
      int newPosition = selectedPiece! + diceRoll!;
      if (newPosition < 30 && board[newPosition] == null) {
        setState(() {
          board[newPosition] = currentPlayer;
          board[selectedPiece!] = null;
          selectedPiece = null;
          diceRoll = null;
          currentPlayer = (currentPlayer == 1) ? 2 : 1;
        });
      }
    }
  }

  Color getTileColor(int index) {
    if (index == 14) return Colors.green; // Casa della Vita
    if (index == 25) return Colors.yellow; // Casa della Felicità
    if (index == 26) return Colors.blue; // Casa dell'Acqua
    if (index >= 27) return Colors.orange; // Uscita
    return Colors.brown.shade300; // Normale
  }

  Widget getPiece(int? player) {
    if (player == 1) {
      return Icon(Icons.circle, color: Colors.red, size: 24);
    } else if (player == 2) {
      return Icon(Icons.square, color: Colors.blue, size: 24);
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
              onPressed: rollDice,
              child: Text('Lancia i bastoncini'),
            ),
            if (diceRoll != null) Text('Risultato: $diceRoll'),
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
