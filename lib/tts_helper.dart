import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

class TtsHelper {
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _isInit = false;

  static Future<void> init() async {
    if (_isInit) return;
    try {
      // Find a suitable Spanish voice
      List<dynamic> languages = await _flutterTts.getLanguages;
      String langToSet = "es-ES";
      for (var l in languages) {
        String langStr = l.toString().toLowerCase();
        if (langStr == "es-mx" || langStr == "es_mx") {
          langToSet = l.toString();
          break;
        } else if (langStr.startsWith("es")) {
          langToSet = l.toString();
        }
      }
      await _flutterTts.setLanguage(langToSet);
      await _flutterTts.setSpeechRate(0.5); // Default speed for natural fluency
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      _isInit = true;
    } catch (e) {
      debugPrint("Error initializing TTS: $e");
    }
  }

  static String _cleanTextForTts(String text) {
    String t = text.trim().toLowerCase();
    if (t.toLowerCase().startsWith('rr')) {
      t = t.substring(1); 
    }
    return t;
  }

  static Future<void> speak(String text) async {
    try {
      await init();
      // On web, calling stop() right before speak() can cause SpeechSynthesisErrorEvent
      if (!kIsWeb) {
        await _flutterTts.stop();
      }
      await _flutterTts.speak(_cleanTextForTts(text));
    } catch (e) {
      debugPrint("Speak error: $e");
    }
  }
  
  static Future<void> stop() async {
    await _flutterTts.stop();
  }
}
