import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class SenetRulesDialog extends StatefulWidget {
  const SenetRulesDialog({super.key});

  @override
  State<SenetRulesDialog> createState() => _SenetRulesDialogState();
}

class _SenetRulesDialogState extends State<SenetRulesDialog> {
  String rulesText = 'Caricamento regole...';

  @override
  void initState() {
    super.initState();
    loadRules();
  }

  Future<void> loadRules() async {
    final String text = await rootBundle.loadString('assets/rules.txt');
    setState(() {
      rulesText = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black.withOpacity(0.85),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Regole di Senet', style: TextStyle(color: Colors.white)),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Text(rulesText, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
