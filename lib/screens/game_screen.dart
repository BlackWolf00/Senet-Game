import 'package:flutter/material.dart';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../logic/ai_logic.dart';
import '../logic/game_logic.dart';
import '../ui/game_ui.dart';
import '../screens/win_dialog.dart';
import '../screens/game_rules_dialog.dart';
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
      if (widget.vsAI && currentPlayer == 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Nessuna mossa possibile, turno saltato."),
            duration: Duration(seconds: 1),
          ),
        );
      }
      setState(() {
        diceRoll = null;
        canRollDice = true;
        currentPlayer = (currentPlayer == 1) ? 2 : 1; // Cambia turno
        _pulse.value = true;
      });
      if (!isMuted && !(widget.vsAI && currentPlayer == 2)) {
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

    List<int> validMoves = getValidMoves(board, diceRoll, 2);
    if (validMoves.isEmpty) return;

    int choice = selectAIMove(
      validMoves,
      widget.aiDifficulty,
      diceRoll,
      board,
      currentPlayer,
    );
    selectedPiece = choice;
    movePiece();
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
        if (!isMuted && !(widget.vsAI && currentPlayer == 2)) {
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
              if (selectedPiece == 25 &&
                  newPosition >= 27 &&
                  newPosition <= 29) {
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
          if (!isMuted && !(widget.vsAI && currentPlayer == 2)) {
            playTurnSound(_audioPlayer);
          }
          if (await Vibration.hasAmplitudeControl()) {
            Vibration.vibrate(amplitude: 128);
          }
        }
      }
    }
    if (widget.vsAI && currentPlayer == 2) aiPlay();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Senet'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.help_outline),
                  tooltip: 'Regole del gioco',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const SenetRulesDialog(),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(isMuted ? Icons.volume_off : Icons.volume_up),
                  tooltip: isMuted ? 'Audio disattivato' : 'Audio attivato',
                  onPressed: _toggleMute,
                ),
                IconButton(
                  icon: const Icon(Icons.home),
                  tooltip: 'Torna al menu principale',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          final double maxContentWidth =
              screenWidth > 700 ? 700 : screenWidth * 0.95;

          return Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/sfondo.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: 300,
                    maxWidth: maxContentWidth,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        const Text(
                          "Punteggio",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "Giocatore Rosso: $player1Score | Giocatore Nero: $player2Score",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Turno giocatore / IA
                        ValueListenableBuilder<bool>(
                          valueListenable: _pulse,
                          builder: (context, pulse, child) {
                            return AnimatedScale(
                              scale: pulse ? 1.1 : 1.0,
                              duration: const Duration(milliseconds: 250),
                              onEnd: () => _pulse.value = false,
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
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
                                    const SizedBox(width: 8),
                                    Text(
                                      widget.vsAI && currentPlayer == 2
                                          ? "Turno dell'IA"
                                          : currentPlayer == 1
                                          ? "Turno del Giocatore Rosso"
                                          : "Turno del Giocatore Nero",
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

                        // Griglia del gioco
                        LayoutBuilder(
                          builder: (context, gridConstraints) {
                            final double gridTileSize =
                                (maxContentWidth - 80) / 10;

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 10,
                                    mainAxisSpacing: 4,
                                    crossAxisSpacing: 4,
                                    childAspectRatio: 1.0,
                                  ),
                              itemCount: 30,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap:
                                      () => selectPiece(
                                        index,
                                        board,
                                        currentPlayer,
                                      ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: getTileColor(
                                        index,
                                        selectedPiece,
                                        diceRoll,
                                      ),
                                      border: Border.all(color: Colors.white),
                                    ),
                                    child: Center(
                                      child: getPiece(board[index]),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed:
                              (canRollDice &&
                                      !(widget.vsAI && currentPlayer == 2))
                                  ? rollDice
                                  : null,
                          child: const Text('Lancia i bastoncini'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Risultato: ${diceRoll ?? ""}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed:
                              !(widget.vsAI && currentPlayer == 2)
                                  ? movePiece
                                  : null,
                          child: const Text('Muovi pezzo'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: resetGame,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                          ),
                          child: const Text("Resetta Partita"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
