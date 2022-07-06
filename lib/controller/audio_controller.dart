

import 'package:audioplayers/audioplayers.dart';



class MyAudio {
  AudioPlayer audioPlayer = AudioPlayer();
 
Future<void> playSound() async {
  try{
    audioPlayer.release();         
   await audioPlayer.play(AssetSource('audio/clip.mp3'));
  } catch(err){
    print(err);
  }
}

}