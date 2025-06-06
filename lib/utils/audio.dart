import 'package:audioplayers/audioplayers.dart';

void playTurnSound(audioPlayer) async {
  try {
    await audioPlayer.play(AssetSource('sounds/turn.mp3'));
  } catch (e) {
    print("Errore audio: $e");
  }
}
