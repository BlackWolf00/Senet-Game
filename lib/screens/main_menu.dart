import 'package:flutter/material.dart';
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