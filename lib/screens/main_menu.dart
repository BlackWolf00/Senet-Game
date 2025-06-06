import 'package:flutter/material.dart';
import '../multiplayer/screen/online_game_dialog.dart';
import '../screens/game_screen.dart';
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
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5), // Sfondo semi-trasparente
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Seleziona difficoltà IA:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 250,
                  child: DropdownButtonFormField<AIDifficulty>(
                    value: selectedDifficulty,
                    dropdownColor: Colors.grey[900],
                    // Colore menu a tendina
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.withOpacity(0.8), // Sfondo interno
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
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
                ),
                const SizedBox(height: 30),
                _buildModeButton('Gioca contro l\'IA', true),
                const SizedBox(height: 20),
                _buildModeButton('Multiplayer Locale', false),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const OnlineGameDialog(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
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
      child: Text(label),
    );
  }
}
