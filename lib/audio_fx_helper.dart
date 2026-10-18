import 'package:flutter/foundation.dart';
import 'audio_fx_stub.dart' if (dart.library.js_interop) 'audio_fx_web.dart';
import 'tts_helper.dart';

class AudioFx {
  static void playCorrect() {
    if (kIsWeb) {
      playWebAudio('correct');
    } else {
      TtsHelper.speak('¡Muy bien!');
    }
  }

  static void playWrong() {
    if (kIsWeb) {
      playWebAudio('wrong');
    } else {
      TtsHelper.speak('¡Inténtalo otra vez!');
    }
  }

  static void playVictory() {
    if (kIsWeb) {
      playWebAudio('win');
    } else {
      TtsHelper.speak('¡Excelente trabajo, felicidades!');
    }
  }

  static void playStar() {
    if (kIsWeb) {
      playWebAudio('star');
    } else {
      TtsHelper.speak('¡Nueva estrella!');
    }
  }
}
