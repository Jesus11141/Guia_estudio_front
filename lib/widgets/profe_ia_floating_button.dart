import 'dart:async';
import 'package:flutter/material.dart';
import 'ai_tutor_sheet.dart';
import 'talking_robot_avatar.dart';
import '../tts_helper.dart';

/// Botón flotante del Profe IA interactivo con globo de saludo periódico
/// y micro-expresiones dinámicas.
class ProfeIaFloatingButton extends StatefulWidget {
  final String? lessonTitle;
  final String? lessonContent;
  final String? subjectName;
  final String? gradeName;

  const ProfeIaFloatingButton({
    super.key,
    this.lessonTitle,
    this.lessonContent,
    this.subjectName,
    this.gradeName,
  });

  @override
  State<ProfeIaFloatingButton> createState() => _ProfeIaFloatingButtonState();
}

class _ProfeIaFloatingButtonState extends State<ProfeIaFloatingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _bubbleAnimCtrl;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  Timer? _initialTimer;
  Timer? _autoHideTimer;
  Timer? _periodicTimer;

  bool _isBubbleVisible = false;
  String _currentBubbleText = '';
  int _phraseIndex = 0;

  List<String> get _phrases {
    if (widget.lessonTitle != null && widget.lessonTitle!.isNotEmpty) {
      return [
        '¿Tienes dudas sobre esta lección? ¡Pregúntame! ✨',
        '¡Puedo darte un ejemplo fácil o un resumen rápido! 💡',
        '¿Quieres un mini-reto sobre "${widget.lessonTitle}"? 🎯',
        '¡Pregúntame cualquier duda de esta lección! 🤖',
      ];
    } else if (widget.subjectName != null && widget.subjectName!.isNotEmpty) {
      return [
        '¿Tienes dudas con ${widget.subjectName}? ¡Pregúntame! 💡',
        '¡Aprender ${widget.subjectName} es fácil conmigo! ✨',
        '¿Necesitas ayuda con tus tareas de hoy? 📚',
      ];
    } else if (widget.gradeName != null && widget.gradeName!.isNotEmpty) {
      return [
        '¡Hola! ¿Tienes dudas con tus materias? ¡Pregúntame! 🚀',
        'Estoy listo para explicarte cualquier tema paso a paso 🤖',
      ];
    }
    return [
      '¡Hola! ¿Tienes dudas con tus tareas? ¡Pregúntame! 🤖',
      '¿Quieres que te explique algún tema difícil? ¡Tócame aquí! ✨',
      '¡Aprender es divertido! Pregúntame lo que quieras 🌟',
    ];
  }

  @override
  void initState() {
    super.initState();

    _bubbleAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _bubbleAnimCtrl,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _bubbleAnimCtrl,
      curve: Curves.easeInOut,
    );

    _currentBubbleText = _phrases.first;

    // Mostrar el primer saludo tras 2.2 segundos de entrar a la pantalla
    _initialTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) _showBubble();
    });

    // Repetir periódicamente cada 42 segundos
    _periodicTimer = Timer.periodic(const Duration(seconds: 42), (timer) {
      if (!mounted) return;
      if (!_isBubbleVisible) {
        _phraseIndex = (_phraseIndex + 1) % _phrases.length;
        _currentBubbleText = _phrases[_phraseIndex];
        _showBubble();
      }
    });
  }

  void _showBubble() {
    setState(() => _isBubbleVisible = true);
    _bubbleAnimCtrl.forward();

    // Auto ocultar después de 8 segundos si no se interactúa
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(milliseconds: 8200), () {
      if (mounted && _isBubbleVisible) {
        _hideBubble();
      }
    });
  }

  void _hideBubble() {
    _bubbleAnimCtrl.reverse().then((_) {
      if (mounted) {
        setState(() => _isBubbleVisible = false);
      }
    });
  }

  void _openTutor() {
    _hideBubble();
    AiTutorSheet.show(
      context,
      lessonTitle: widget.lessonTitle,
      lessonContent: widget.lessonContent,
    );
  }

  @override
  void dispose() {
    _initialTimer?.cancel();
    _autoHideTimer?.cancel();
    _periodicTimer?.cancel();
    _bubbleAnimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<bool>(
      valueListenable: TtsHelper.isSpeakingNotifier,
      builder: (context, isSpeaking, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ─── Globo de saludo periódico (Bocadillo de diálogo) ────
            if (_isBubbleVisible)
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0, right: 4.0),
                    child: _buildSpeechBubble(context, isDark),
                  ),
                ),
              ),

            // ─── Botón Flotante con Avatar Parlante ───────────────────
            GestureDetector(
              onTap: _openTutor,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Avatar animado con micro-expresiones y ondas
                    TalkingRobotAvatar(
                      size: 34,
                      isSpeaking: isSpeaking,
                      isThinking: false,
                      showSoundWaves: isSpeaking,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Profe IA',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Text('✨', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSpeechBubble(BuildContext context, bool isDark) {
    final bubbleBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final borderColor = isDark ? const Color(0xFF4F46E5).withOpacity(0.6) : const Color(0xFF6366F1).withOpacity(0.3);

    return InkWell(
      onTap: _openTutor,
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomRight,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 250),
            padding: const EdgeInsets.fromLTRB(14, 10, 28, 12),
            decoration: BoxDecoration(
              color: bubbleBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    _currentBubbleText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Botón de cerrar pequeño 'x'
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: _hideBubble,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
