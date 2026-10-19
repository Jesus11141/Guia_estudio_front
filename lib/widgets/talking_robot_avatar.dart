import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Un avatar de robot interactivo y vivo ("Profe IA")
/// Cuenta con:
/// - Parpadeo ocular periódico natural (cada ~3.5s)
/// - Micro-expresiones dinámicas (ojos felices al hablar, mirada curiosa al pensar)
/// - Boca interactiva (barras de ecualizador al hablar, puntos al pensar, sonrisa en reposo)
/// - Ondas de sonido concéntricas radiantes cuando habla o explica
class TalkingRobotAvatar extends StatefulWidget {
  final double size;
  final bool isSpeaking;
  final bool isThinking;
  final bool showSoundWaves;

  const TalkingRobotAvatar({
    super.key,
    this.size = 48.0,
    this.isSpeaking = false,
    this.isThinking = false,
    this.showSoundWaves = false,
  });

  @override
  State<TalkingRobotAvatar> createState() => _TalkingRobotAvatarState();
}

class _TalkingRobotAvatarState extends State<TalkingRobotAvatar>
    with TickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;
  Timer? _blinkTimer;

  late AnimationController _speechController;
  late AnimationController _waveController;
  late AnimationController _thinkController;

  @override
  void initState() {
    super.initState();

    // 1. Parpadeo de ojos
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _blinkAnimation = CurvedAnimation(
      parent: _blinkController,
      curve: Curves.easeInOut,
    );

    _startBlinkCycle();

    // 2. Movimiento de boca / voz (ecualizador)
    _speechController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    if (widget.isSpeaking) {
      _speechController.repeat(reverse: true);
    }

    // 3. Ondas concéntricas de sonido
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    if (widget.isSpeaking || widget.showSoundWaves) {
      _waveController.repeat();
    }

    // 4. Animación de pensamiento (glow de antena)
    _thinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.isThinking) {
      _thinkController.repeat(reverse: true);
    }
  }

  void _startBlinkCycle() {
    _blinkTimer?.cancel();
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 3400), (timer) {
      if (!mounted) return;
      if (!widget.isSpeaking) {
        _blinkController.forward().then((_) {
          if (mounted) {
            _blinkController.reverse();
          }
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant TalkingRobotAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);

    final wavesActive = widget.isSpeaking || widget.showSoundWaves;
    final oldWavesActive = oldWidget.isSpeaking || oldWidget.showSoundWaves;

    if (wavesActive && !oldWavesActive) {
      _waveController.repeat();
    } else if (!wavesActive && oldWavesActive) {
      _waveController.stop();
      _waveController.reset();
    }

    if (widget.isSpeaking && !oldWidget.isSpeaking) {
      _speechController.repeat(reverse: true);
    } else if (!widget.isSpeaking && oldWidget.isSpeaking) {
      _speechController.stop();
      _speechController.reset();
    }

    if (widget.isThinking && !oldWidget.isThinking) {
      _thinkController.repeat(reverse: true);
    } else if (!widget.isThinking && oldWidget.isThinking) {
      _thinkController.stop();
      _thinkController.reset();
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _blinkController.dispose();
    _speechController.dispose();
    _waveController.dispose();
    _thinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si hay ondas de sonido, le damos margen para que se expandan suavemente
    final double canvasSize = widget.size * (widget.showSoundWaves || widget.isSpeaking ? 1.6 : 1.15);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _blinkAnimation,
          _speechController,
          _waveController,
          _thinkController,
        ]),
        builder: (context, _) {
          return SizedBox(
            width: canvasSize,
            height: canvasSize,
            child: CustomPaint(
              painter: _RobotAvatarPainter(
                blinkValue: _blinkAnimation.value,
                speechProgress: _speechController.value,
                waveProgress: _waveController.value,
                thinkProgress: _thinkController.value,
                isSpeaking: widget.isSpeaking,
                isThinking: widget.isThinking,
                showSoundWaves: widget.isSpeaking || widget.showSoundWaves,
                baseSize: widget.size,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RobotAvatarPainter extends CustomPainter {
  final double blinkValue;
  final double speechProgress;
  final double waveProgress;
  final double thinkProgress;
  final bool isSpeaking;
  final bool isThinking;
  final bool showSoundWaves;
  final double baseSize;

  _RobotAvatarPainter({
    required this.blinkValue,
    required this.speechProgress,
    required this.waveProgress,
    required this.thinkProgress,
    required this.isSpeaking,
    required this.isThinking,
    required this.showSoundWaves,
    required this.baseSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = baseSize / 100.0; // Normalizado a un canvas conceptual de 100x100

    // ─────────────────────────────────────────────────────────────────
    // 1. ONDAS DE SONIDO CONCÉNTRICAS (SOUND WAVES RADIATING)
    // ─────────────────────────────────────────────────────────────────
    if (showSoundWaves) {
      final wavePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // 3 ondas desfasadas
      for (int i = 0; i < 3; i++) {
        final double phase = (waveProgress + (i * 0.33)) % 1.0;
        final double waveRadius = (baseSize * 0.46) + (phase * baseSize * 0.28);
        final double waveOpacity = (1.0 - phase).clamp(0.0, 1.0) * 0.55;

        wavePaint.color = Color.lerp(
          const Color(0xFF6366F1), // Indigo
          const Color(0xFF06B6D4), // Cyan brillante
          i / 2.0,
        )!.withOpacity(waveOpacity);
        wavePaint.strokeWidth = 2.2 * scale.clamp(0.8, 2.0);

        canvas.drawCircle(center, waveRadius, wavePaint);
      }
    }

    // ─────────────────────────────────────────────────────────────────
    // 2. ANTENA SUPERIOR CON ORBE BRILLANTE
    // ─────────────────────────────────────────────────────────────────
    final antennaStemPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 * scale
      ..strokeCap = StrokeCap.round;

    final stemBottom = center + Offset(0, -32 * scale);
    final stemTop = center + Offset(0, -42 * scale);
    canvas.drawLine(stemBottom, stemTop, antennaStemPaint);

    // Orbe de antena
    final orbRadius = 4.5 * scale;
    Color orbColor = const Color(0xFF38BDF8); // Cyan normal
    if (isThinking) {
      orbColor = Color.lerp(const Color(0xFFF59E0B), const Color(0xFFEF4444), thinkProgress)!;
    } else if (isSpeaking) {
      orbColor = Color.lerp(const Color(0xFF10B981), const Color(0xFF06B6D4), speechProgress)!;
    }

    // Glow del orbe
    final orbGlowPaint = Paint()
      ..color = orbColor.withOpacity(0.5 + (0.4 * (isThinking ? thinkProgress : (isSpeaking ? speechProgress : 0.2))))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.0 * scale);
    canvas.drawCircle(stemTop, orbRadius * 1.5, orbGlowPaint);

    final orbPaint = Paint()..color = orbColor;
    canvas.drawCircle(stemTop, orbRadius, orbPaint);

    // ─────────────────────────────────────────────────────────────────
    // 3. OREJITAS / AUDÍFONOS LATERALES DEL ROBOT
    // ─────────────────────────────────────────────────────────────────
    final earPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: 45 * scale));

    final leftEarRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center + Offset(-35 * scale, 0), width: 8 * scale, height: 22 * scale),
      Radius.circular(4 * scale),
    );
    final rightEarRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center + Offset(35 * scale, 0), width: 8 * scale, height: 22 * scale),
      Radius.circular(4 * scale),
    );
    canvas.drawRRect(leftEarRect, earPaint);
    canvas.drawRRect(rightEarRect, earPaint);

    // ─────────────────────────────────────────────────────────────────
    // 4. CABEZA DEL ROBOT (SQUIRCLE GRADIENTE SUAVE)
    // ─────────────────────────────────────────────────────────────────
    final headRect = Rect.fromCenter(
      center: center,
      width: 66 * scale,
      height: 60 * scale,
    );
    final headRRect = RRect.fromRectAndRadius(headRect, Radius.circular(18 * scale));

    // Sombra suave de la cabeza
    canvas.drawRRect(
      headRRect.shift(Offset(0, 3 * scale)),
      Paint()
        ..color = const Color(0xFF312E81).withOpacity(0.25)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6.0 * scale),
    );

    // Fondo degradado de la cabeza
    final headPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFF4338CA), Color(0xFF3730A3)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(headRect);
    canvas.drawRRect(headRRect, headPaint);

    // Borde brillante fino de la cabeza
    canvas.drawRRect(
      headRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6 * scale
        ..shader = const LinearGradient(
          colors: [Color(0xFFA5B4FC), Color(0xFF4338CA)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(headRect),
    );

    // ─────────────────────────────────────────────────────────────────
    // 5. PANTALLA VISOR DIGITAL (NEGRO PROFUNDO CON GLOW)
    // ─────────────────────────────────────────────────────────────────
    final visorRect = Rect.fromCenter(
      center: center + Offset(0, 1 * scale),
      width: 52 * scale,
      height: 42 * scale,
    );
    final visorRRect = RRect.fromRectAndRadius(visorRect, Radius.circular(13 * scale));

    final visorPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawRRect(visorRRect, visorPaint);

    // Borde sutil del visor
    canvas.drawRRect(
      visorRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * scale
        ..color = const Color(0xFF1E293B),
    );

    // ─────────────────────────────────────────────────────────────────
    // 6. OJOS CON MICRO-EXPRESIONES & PARPADEO
    // ─────────────────────────────────────────────────────────────────
    final eyeY = center.dy - (4 * scale);
    final leftEyeX = center.dx - (13 * scale);
    final rightEyeX = center.dx + (13 * scale);

    final eyeGlowPaint = Paint()
      ..color = const Color(0xFF38BDF8).withOpacity(0.8)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.0 * scale);

    final eyeColor = const Color(0xFF38BDF8); // Cyan digital
    final eyePaint = Paint()
      ..color = eyeColor
      ..style = PaintingStyle.fill;

    if (isSpeaking) {
      // Ojos felices tipo "^  ^"
      final happyEyePaint = Paint()
        ..color = const Color(0xFF38BDF8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4 * scale
        ..strokeCap = StrokeCap.round;

      final leftPath = Path()
        ..moveTo(leftEyeX - 5 * scale, eyeY + 1 * scale)
        ..quadraticBezierTo(leftEyeX, eyeY - 5 * scale, leftEyeX + 5 * scale, eyeY + 1 * scale);

      final rightPath = Path()
        ..moveTo(rightEyeX - 5 * scale, eyeY + 1 * scale)
        ..quadraticBezierTo(rightEyeX, eyeY - 5 * scale, rightEyeX + 5 * scale, eyeY + 1 * scale);

      canvas.drawPath(leftPath, happyEyePaint);
      canvas.drawPath(rightPath, happyEyePaint);
    } else {
      // Ojos normales con parpadeo animado
      final currentBlink = blinkValue; // 0.0 abierto, 1.0 cerrado
      final eyeHeight = math.max(1.5 * scale, (11 * scale) * (1.0 - currentBlink));
      final eyeWidth = 8.5 * scale;

      final leftEyeRRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(leftEyeX, eyeY), width: eyeWidth, height: eyeHeight),
        Radius.circular(4 * scale),
      );
      final rightEyeRRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(rightEyeX, eyeY), width: eyeWidth, height: eyeHeight),
        Radius.circular(4 * scale),
      );

      // Glow suave de ojos
      canvas.drawRRect(leftEyeRRect, eyeGlowPaint);
      canvas.drawRRect(rightEyeRRect, eyeGlowPaint);

      // Dibujar ojos
      canvas.drawRRect(leftEyeRRect, eyePaint);
      canvas.drawRRect(rightEyeRRect, eyePaint);

      // Pequeño reflejo de brillo en los ojos si están abiertos
      if (currentBlink < 0.5) {
        final pupilGlint = Paint()..color = Colors.white.withOpacity(0.9);
        canvas.drawCircle(Offset(leftEyeX + 1.8 * scale, eyeY - 2.2 * scale), 1.5 * scale, pupilGlint);
        canvas.drawCircle(Offset(rightEyeX + 1.8 * scale, eyeY - 2.2 * scale), 1.5 * scale, pupilGlint);
      }
    }

    // ─────────────────────────────────────────────────────────────────
    // 7. BOCA INTERACTIVA (ECUALIZADOR AL HABLAR / PUNTOS / SONRISA)
    // ─────────────────────────────────────────────────────────────────
    final mouthY = center.dy + (10 * scale);

    if (isSpeaking) {
      // Barras dinámicas de ecualizador digital al hablar
      final barPaint = Paint()
        ..color = const Color(0xFF34D399) // Verde esmeralda alegre
        ..style = PaintingStyle.fill;

      const barCount = 4;
      final totalWidth = 20 * scale;
      final barWidth = 3.0 * scale;
      final startX = center.dx - (totalWidth / 2) + (barWidth / 2);

      for (int i = 0; i < barCount; i++) {
        final x = startX + (i * 5.2 * scale);
        // Oscilador con diferente fase para cada barrita
        final offset = (i * 0.75);
        final dynamicHeight = 3.0 * scale + (math.sin(speechProgress * math.pi * 2 + offset).abs() * 7.5 * scale);

        final barRRect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, mouthY), width: barWidth, height: dynamicHeight),
          Radius.circular(1.5 * scale),
        );
        canvas.drawRRect(barRRect, barPaint);
      }
    } else if (isThinking) {
      // Puntos suspensivos pensando "• • •"
      final dotPaint = Paint()..color = const Color(0xFFFBBF24); // Ámbar
      for (int i = -1; i <= 1; i++) {
        final phaseOffset = (i + 1) * 0.33;
        final bounce = math.sin((thinkProgress + phaseOffset) * math.pi * 2) * (2 * scale);
        canvas.drawCircle(Offset(center.dx + (i * 6 * scale), mouthY + bounce), 1.6 * scale, dotPaint);
      }
    } else {
      // Sonrisa sutil amigable
      final smilePaint = Paint()
        ..color = const Color(0xFF38BDF8).withOpacity(0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * scale
        ..strokeCap = StrokeCap.round;

      final smilePath = Path()
        ..moveTo(center.dx - 6 * scale, mouthY - 1 * scale)
        ..quadraticBezierTo(center.dx, mouthY + 3.5 * scale, center.dx + 6 * scale, mouthY - 1 * scale);

      canvas.drawPath(smilePath, smilePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RobotAvatarPainter oldDelegate) {
    return oldDelegate.blinkValue != blinkValue ||
        oldDelegate.speechProgress != speechProgress ||
        oldDelegate.waveProgress != waveProgress ||
        oldDelegate.thinkProgress != thinkProgress ||
        oldDelegate.isSpeaking != isSpeaking ||
        oldDelegate.isThinking != isThinking ||
        oldDelegate.showSoundWaves != showSoundWaves ||
        oldDelegate.baseSize != baseSize;
  }
}
