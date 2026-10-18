import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiCelebration extends StatefulWidget {
  final Widget child;
  final bool isActive;

  const ConfettiCelebration({
    super.key,
    required this.child,
    this.isActive = true,
  });

  @override
  State<ConfettiCelebration> createState() => _ConfettiCelebrationState();
}

class _ConfettiCelebrationState extends State<ConfettiCelebration> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final Random _random = Random();

  final List<Color> _colors = [
    const Color(0xFFEF4444), // Red
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF10B981), // Emerald
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFEC4899), // Pink
    const Color(0xFF06B6D4), // Cyan
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    if (widget.isActive) {
      _initParticles();
      _controller.forward();
    }
  }

  void _initParticles() {
    _particles.clear();
    for (int i = 0; i < 65; i++) {
      _particles.add(_ConfettiParticle(
        x: _random.nextDouble(),
        y: -0.1 - _random.nextDouble() * 0.4,
        size: 8.0 + _random.nextDouble() * 8.0,
        color: _colors[_random.nextInt(_colors.length)],
        speed: 0.3 + _random.nextDouble() * 0.5,
        swaySpeed: 1.5 + _random.nextDouble() * 2.5,
        swayWidth: 0.03 + _random.nextDouble() * 0.05,
        rotationSpeed: 2.0 + _random.nextDouble() * 4.0,
        isCircle: _random.nextBool(),
      ));
    }
  }

  @override
  void didUpdateWidget(covariant ConfettiCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _initParticles();
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isActive)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _ConfettiPainter(
                      progress: _controller.value,
                      particles: _particles,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _ConfettiParticle {
  final double x;
  final double y;
  final double size;
  final Color color;
  final double speed;
  final double swaySpeed;
  final double swayWidth;
  final double rotationSpeed;
  final bool isCircle;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.speed,
    required this.swaySpeed,
    required this.swayWidth,
    required this.rotationSpeed,
    required this.isCircle,
  });
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_ConfettiParticle> particles;

  _ConfettiPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      // Calculate current position with gravity and sway
      final currentY = (p.y + progress * (1.3 + p.speed)) * size.height;
      final currentX = (p.x + sin(progress * pi * 2 * p.swaySpeed) * p.swayWidth) * size.width;

      if (currentY > size.height + 20) continue;

      final paint = Paint()
        ..color = p.color.withOpacity((1.0 - (progress * 0.8)).clamp(0.2, 1.0))
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(progress * pi * 2 * p.rotationSpeed);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
