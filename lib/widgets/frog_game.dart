import 'package:flutter/material.dart';
import '../models.dart';

class FrogGameWidget extends StatefulWidget {
  final Question question;
  final bool hasAnswered;
  final bool isCorrect;
  
  const FrogGameWidget({
    super.key, 
    required this.question,
    this.hasAnswered = false,
    this.isCorrect = false,
  });

  @override
  State<FrogGameWidget> createState() => _FrogGameWidgetState();
}

class _FrogGameWidgetState extends State<FrogGameWidget> with SingleTickerProviderStateMixin {
  late int startNum;
  late int step;
  late int jumps;
  
  late AnimationController _controller;
  late Animation<double> _jumpAnimation;
  int _currentJump = 0;

  @override
  void initState() {
    super.initState();
    startNum = widget.question.metadata?['startNumber'] ?? 2;
    step = widget.question.metadata?['step'] ?? 2;
    jumps = widget.question.metadata?['jumps'] ?? 4;
    
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _jumpAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOutQuad));
  }
  
  @override
  void didUpdateWidget(FrogGameWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If user just answered correctly, auto-trigger the final jump
    if (!oldWidget.hasAnswered && widget.hasAnswered && widget.isCorrect) {
      if (_currentJump < jumps) {
        setState(() {
          _currentJump = jumps - 1; // Snap to second-to-last pad to animate the final jump
        });
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _controller.forward(from: 0).then((_) {
              if (mounted) {
                setState(() { _currentJump++; });
                _controller.reset();
              }
            });
          }
        });
      }
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _jumpFrog() {
    // Only allow manual jumps up to the second-to-last pad
    if (_currentJump < jumps - 1) {
      _controller.forward(from: 0).then((_) {
        if (mounted) {
          setState(() {
            _currentJump++;
          });
          _controller.reset();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.blue.shade200, width: 2),
      ),
      child: Column(
        children: [
          Text('¡La Rana Saltarina!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF60A5FA) : Colors.blue)),
          const SizedBox(height: 16),
          Text('Patrón: +$step', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF4ADE80) : Colors.green)),
          const SizedBox(height: 40),
          
          SizedBox(
            height: 120,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // The lily pads (leaves)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(jumps + 1, (index) {
                          bool isRevealed = index <= _currentJump;
                          bool isFinalPad = index == jumps;
                          bool revealFinalNumber = isFinalPad && widget.hasAnswered && widget.isCorrect && _currentJump == jumps;
                          
                          int padValue = startNum + (index * step);
                          return Container(
                            width: 40,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.green.shade600,
                              borderRadius: BorderRadius.circular(20), // looks like a leaf
                            ),
                            child: Center(
                              child: Text(
                                (isRevealed && !isFinalPad) || revealFinalNumber ? '$padValue' : '?', 
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    
                    // The Frog Animation
                    AnimatedBuilder(
                      animation: _jumpAnimation,
                      builder: (context, child) {
                        double totalWidth = constraints.maxWidth - 40; // Subtract pad width to center on pad
                        double distancePerJump = totalWidth / jumps;
                        
                        // Calculate X position
                        double startX = _currentJump * distancePerJump;
                        double currentX = startX + (_jumpAnimation.value * distancePerJump);
                        if (_currentJump == jumps) currentX = startX; // Don't jump past end
                        
                        // Calculate Y position (parabola)
                        double jumpHeight = 60.0;
                        double currentY = jumpHeight * (4 * _jumpAnimation.value * (1 - _jumpAnimation.value));
                        if (_currentJump == jumps) currentY = 0;

                        return Positioned(
                          left: currentX - 20, // Offset by padding to center the frog exactly on the pad
                          bottom: currentY,    // Offset by padding to sit perfectly on top of the pad
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _jumpFrog,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              color: Colors.transparent,
                              child: const Text('🐸', style: TextStyle(fontSize: 40)),
                            ),
                          ),
                        );
                      }
                    )
                  ],
                );
              }
            ),
          ),
          const SizedBox(height: 16),
          Text('Toca la rana para que salte y descubre el último número.', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.black54, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}
