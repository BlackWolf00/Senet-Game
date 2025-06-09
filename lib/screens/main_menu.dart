import 'package:flutter/material.dart';
import '../multiplayer/screen/online_game_dialog.dart';
import '../screens/game_screen.dart';
import '../screens/game_rules_dialog.dart';
import '../utils/ai_difficulty.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  _MainMenuState createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  AIDifficulty selectedDifficulty = AIDifficulty.easy;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double containerWidth = screenWidth * 0.85;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Senet - Menu'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton.icon(
              icon: Icon(Icons.help_outline),
              label: const Text('Regole del gioco'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const SenetRulesDialog(),
                );
              },
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/sfondo.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                width: containerWidth,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Seleziona difficoltà IA:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<AIDifficulty>(
                      value: selectedDifficulty,
                      dropdownColor: Colors.grey[900],
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.withOpacity(0.8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      iconEnabledColor: Colors.white,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedDifficulty = value;
                          });
                        }
                      },
                      items:
                          AIDifficulty.values.map((difficulty) {
                            return DropdownMenuItem(
                              value: difficulty,
                              child: Text(difficulty.name.toUpperCase()),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 32),
                    _buildModeButton('Gioca contro l\'IA', true),
                    const SizedBox(height: 16),
                    _buildModeButton('Multiplayer Locale', false),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const OnlineGameDialog(),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 12.0,
                        ),
                      ),
                      child: const Text('Multiplayer Online'),
                    ),
                  ],
                ),
              ),
            ),
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
            builder:
                (_) => GameScreen(vsAI: vsAI, aiDifficulty: selectedDifficulty),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        textStyle: const TextStyle(fontSize: 16),
      ),
      child: Text(label),
    );
  }
}
