import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

class TtsHelper {
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _isInit = false;

  /// Reactive notifiers for UI animation
  static final ValueNotifier<bool> isSpeakingNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<String?> currentSpeakingTextNotifier = ValueNotifier<String?>(null);

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

      _flutterTts.setStartHandler(() {
        isSpeakingNotifier.value = true;
      });

      _flutterTts.setCompletionHandler(() {
        isSpeakingNotifier.value = false;
        currentSpeakingTextNotifier.value = null;
      });

      _flutterTts.setErrorHandler((_) {
        isSpeakingNotifier.value = false;
        currentSpeakingTextNotifier.value = null;
      });

      _flutterTts.setCancelHandler(() {
        isSpeakingNotifier.value = false;
        currentSpeakingTextNotifier.value = null;
      });

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
      isSpeakingNotifier.value = true;
      currentSpeakingTextNotifier.value = text;

      // Fallback timer in case platform synthesiser completion does not fire
      final wordCount = text.split(RegExp(r'\s+')).length;
      final estimatedDurationMs = (wordCount * 380).clamp(1600, 40000);
      Future.delayed(Duration(milliseconds: estimatedDurationMs), () {
        if (currentSpeakingTextNotifier.value == text) {
          isSpeakingNotifier.value = false;
          currentSpeakingTextNotifier.value = null;
        }
      });

      await _flutterTts.speak(_cleanTextForTts(text));
    } catch (e) {
      isSpeakingNotifier.value = false;
      currentSpeakingTextNotifier.value = null;
      debugPrint("Speak error: $e");
    }
  }
  
  static Future<void> stop() async {
    isSpeakingNotifier.value = false;
    currentSpeakingTextNotifier.value = null;
    await _flutterTts.stop();
  }
}

