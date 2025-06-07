import 'package:flutter/material.dart';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../logic/game_logic.dart';
import '../ui/game_ui.dart';
import '../screens/win_dialog.dart';
import '../utils/ai_difficulty.dart';
import '../utils/audio.dart';

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
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ValueNotifier<bool> _pulse = ValueNotifier(false);
  bool isMuted = false;

  @override
  void initState() {
    super.initState();
    initializeBoard(board);
    _loadMutePreference();
  }

  void _loadMutePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isMuted = prefs.getBool('isMuted') ?? false;
    });
  }

  void _toggleMute() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isMuted = !isMuted;
      prefs.setBool('isMuted', isMuted);
    });
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

  void rollDice() async {
    if (!canRollDice) return;
    int count = List.generate(
      4,
      (_) => Random().nextBool() ? 1 : 0,
    ).reduce((a, b) => a + b);
    setState(() {
      diceRoll = (count == 0) ? 5 : count;
      canRollDice = false;
    });
    if (!hasPossibleMove(board, currentPlayer, diceRoll)) {
      setState(() {
        diceRoll = null;
        canRollDice = true;
        currentPlayer = (currentPlayer == 1) ? 2 : 1; // Cambia turno
        _pulse.value = true;
      });
      if (!isMuted) {
        playTurnSound(_audioPlayer);
      }
      if (await Vibration.hasAmplitudeControl()) {
        Vibration.vibrate(amplitude: 128);
      }
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

  void movePiece() async {
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
            showWinDialog(context, player1Score == 5 ? 1 : 2, resetGame);
          }
          currentPlayer = (currentPlayer == 1) ? 2 : 1;
          _pulse.value = true;
          canRollDice = true;
        });
        if (!isMuted) {
          playTurnSound(_audioPlayer);
        }
        if (await Vibration.hasAmplitudeControl()) {
          Vibration.vibrate(amplitude: 128);
        }
      }

      if (newPosition < 30) {
        int? occupyingPlayer = board[newPosition];
        if ((occupyingPlayer == null &&
                !isBlockedByThreeGroup(
                  selectedPiece!,
                  newPosition,
                  board,
                  currentPlayer,
                ) &&
                checkHouseOfHappinessRule(selectedPiece!, newPosition) &&
                canExitFromSpecialHouse(selectedPiece!, diceRoll!)) ||
            (occupyingPlayer != null &&
                occupyingPlayer != currentPlayer &&
                !isProtectedFromSwap(newPosition, board) &&
                !isBlockedByThreeGroup(
                  selectedPiece!,
                  newPosition,
                  board,
                  currentPlayer,
                ) &&
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
            _pulse.value = true;
            canRollDice = true;
          });
          if (!isMuted) {
            playTurnSound(_audioPlayer);
          }
          if (await Vibration.hasAmplitudeControl()) {
            Vibration.vibrate(amplitude: 128);
          }
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
            icon: Icon(isMuted ? Icons.volume_off : Icons.volume_up),
            tooltip: isMuted ? 'Audio disattivato' : 'Audio attivato',
            onPressed: _toggleMute,
          ),
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
                  SizedBox(height: 16),
                  ValueListenableBuilder<bool>(
                    valueListenable: _pulse,
                    builder: (context, pulse, child) {
                      return AnimatedScale(
                        scale: pulse ? 1.1 : 1.0,
                        duration: Duration(milliseconds: 250),
                        onEnd: () => _pulse.value = false,
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 12),
                          padding: EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color:
                                widget.vsAI && currentPlayer == 2
                                    ? Colors.indigo.withOpacity(0.7)
                                    : currentPlayer == 1
                                    ? Colors.red.withOpacity(0.7)
                                    : Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.vsAI && currentPlayer == 2
                                    ? Icons.smart_toy
                                    : currentPlayer == 1
                                    ? Icons.person
                                    : Icons.person_outline,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8),
                              Text(
                                widget.vsAI && currentPlayer == 2
                                    ? "Turno dell'IA"
                                    : currentPlayer == 1
                                    ? "Turno del Giocatore 1"
                                    : "Turno del Giocatore 2",
                                style: TextStyle(
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
                        onTap: () => selectPiece(index, board, currentPlayer),
                        child: Container(
                          margin: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: getTileColor(index, selectedPiece, diceRoll),
                            border: Border.all(color: Colors.white),
                          ),
                          child: Center(child: getPiece(board[index])),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: canRollDice ? rollDice : null,
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
                    onPressed: movePiece,
                    child: Text('Muovi pezzo'),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: resetGame,
                    child: Text("Resetta Partita"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
