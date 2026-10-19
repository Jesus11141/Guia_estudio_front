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
      String langToSet = "es-ES";
      try {
        final langs = await _flutterTts.getLanguages;
        if (langs != null && langs is Iterable) {
          for (var l in langs) {
            String langStr = l.toString().toLowerCase();
            if (langStr == "es-mx" || langStr == "es_mx") {
              langToSet = l.toString();
              break;
            } else if (langStr.startsWith("es")) {
              langToSet = l.toString();
            }
          }
        }
      } catch (e) {
        debugPrint("Error fetching TTS languages (using default es-ES): $e");
      }

      await _flutterTts.setLanguage(langToSet);
      await _flutterTts.setSpeechRate(0.5); // Velocidad natural y clara
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      try {
        await _flutterTts.awaitSpeakCompletion(false);
      } catch (_) {}

      _flutterTts.setStartHandler(() {
        isSpeakingNotifier.value = true;
      });

      _flutterTts.setCompletionHandler(() {
        isSpeakingNotifier.value = false;
        currentSpeakingTextNotifier.value = null;
      });

      _flutterTts.setErrorHandler((dynamic msg) {
        debugPrint("TTS Error handler: $msg");
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

  /// Limpia emojis, markdown y símbolos que bloquean la síntesis de voz en navegadores
  static String _cleanTextForTts(String text) {
    String t = text.replaceAll(
      RegExp(
        r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}]',
        unicode: true,
      ),
      '',
    );
    t = t.replaceAll(RegExp(r'\*\*|__'), '');
    t = t.replaceAll(RegExp(r'#+\s*'), '');
    t = t.replaceAll(RegExp(r'^\s*[-*•]\s*', multiLine: true), '');
    t = t.replaceAll(RegExp(r'[<>]'), '');
    return t.trim();
  }

  static Future<void> speak(String text) async {
    try {
      await init();

      // Resetear estado previo con pausa en Web para cancelar de forma limpia
      try {
        await _flutterTts.stop();
        if (kIsWeb) {
          await Future.delayed(const Duration(milliseconds: 70));
        }
      } catch (_) {}

      final cleanText = _cleanTextForTts(text);
      if (cleanText.isEmpty) return;

      isSpeakingNotifier.value = true;
      currentSpeakingTextNotifier.value = text;

      // Timer de seguridad por si el evento de finalización del navegador tarda
      final wordCount = cleanText.split(RegExp(r'\s+')).length;
      final estimatedDurationMs = (wordCount * 360).clamp(2000, 35000);
      Future.delayed(Duration(milliseconds: estimatedDurationMs), () {
        if (currentSpeakingTextNotifier.value == text) {
          isSpeakingNotifier.value = false;
          currentSpeakingTextNotifier.value = null;
        }
      });

      await _flutterTts.speak(cleanText);
    } catch (e) {
      isSpeakingNotifier.value = false;
      currentSpeakingTextNotifier.value = null;
      debugPrint("Speak error: $e");
    }
  }

  static Future<void> stop() async {
    isSpeakingNotifier.value = false;
    currentSpeakingTextNotifier.value = null;
    try {
      await _flutterTts.stop();
    } catch (_) {}
  }
}
