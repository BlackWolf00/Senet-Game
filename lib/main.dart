import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(SenetGame());
}

class SenetGame extends StatefulWidget {
  @override
  _SenetGameState createState() => _SenetGameState();
}

class _SenetGameState extends State<SenetGame> {
  Map<int, String> board = {
    0: 'cone', 1: 'spool', 2: 'cone', 3: 'spool', 4: 'cone',
    5: 'spool', 6: 'cone', 7: 'spool', 8: 'cone', 9: 'spool',
  };

  Map<int, String> specialTiles = {
    14: 'house_of_life',
    25: 'house_of_happiness',
    26: 'house_of_water',
    27: 'exit',
    28: 'exit',
    29: 'exit',
  };

  int diceRoll = 0;

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Senet Game')),
        body: Column(
          children: [
            SizedBox(height: 20),
            Text(
              'Lancio: $diceRoll',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            ElevatedButton(
              onPressed: rollDice,
              child: Text('Lancia i bastoncini!'),
            ),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 10,
                ),
                itemCount: 30,
                itemBuilder: (context, index) {
                  Color tileColor = Colors.brown[300]!;

                  if (specialTiles.containsKey(index)) {
                    switch (specialTiles[index]) {
                      case 'house_of_life':
                        tileColor = Colors.green;
                        break;
                      case 'house_of_happiness':
                        tileColor = Colors.blue;
                        break;
                      case 'house_of_water':
                        tileColor = Colors.lightBlue;
                        break;
                      case 'exit':
                        tileColor = Colors.yellow;
                        break;
                    }
                  }

                  return Container(
                    margin: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: tileColor,
                      border: Border.all(color: Colors.black, width: 1),
                    ),
                    child: Center(
                      child: board.containsKey(index)
                          ? Text(
                        board[index] == 'cone' ? '🔺' : '⚫',
                        style: TextStyle(fontSize: 24),
                      )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
