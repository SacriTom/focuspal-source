// Egg widget for hatching screen. Wobbles with increasing intensity
// as warmth increases. Shows crack overlays at 50%, 65%, 80%.
// At 100%, egg splits and Chibi emerges with elasticOut animation.

import 'dart:math';
import 'package:flutter/material.dart';
import '../models/chibi.dart';

class EggAnimation extends StatefulWidget {
  final ChibiSpecies species;
  final double warmth; // 0.0 to 1.0
  final bool hatched;
  final bool isHolding; // Whether user is currently holding

  const EggAnimation({
    super.key,
    required this.species,
    required this.warmth,
    this.hatched = false,
    this.isHolding = false,
  });

  @override
  State<EggAnimation> createState() => _EggAnimationState();
}

class _EggAnimationState extends State<EggAnimation>
    with TickerProviderStateMixin {
  late AnimationController _wobbleController;
  late AnimationController _hatchController;
  late Animation<double> _hatchScale;

  @override
  void initState() {
    super.initState();
    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _hatchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _hatchScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _hatchController, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(EggAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hatched && !oldWidget.hatched) {
      _hatchController.forward();
    }
    // Adjust wobble speed based on warmth
    final newDuration = Duration(
      milliseconds: max(200, (600 - (widget.warmth * 400)).toInt()),
    );
    if (_wobbleController.duration != newDuration) {
      _wobbleController.duration = newDuration;
    }
  }

  @override
  void dispose() {
    _wobbleController.dispose();
    _hatchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hatched) {
      return _buildHatchedChibi();
    }
    return _buildEgg();
  }

  Widget _buildEgg() {
    // Wobble amplitude increases with warmth: 2 deg at 0%, 8 deg at 100%
    final maxAngle = 2.0 + (widget.warmth * 6.0);

    return AnimatedBuilder(
      animation: _wobbleController,
      builder: (context, child) {
        final angle = widget.isHolding
            ? sin(_wobbleController.value * pi) * maxAngle * (pi / 180)
            : sin(_wobbleController.value * pi) * 2 * (pi / 180);

        return Transform.rotate(
          angle: angle,
          child: child,
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Egg image
          Image.asset(
            widget.species.eggAsset,
            width: 160,
            height: 200,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
            errorBuilder: (context, error, stack) {
              return Container(
                width: 160,
                height: 200,
                decoration: BoxDecoration(
                  color: _eggColor(),
                  borderRadius: BorderRadius.circular(80),
                ),
                child: const Center(
                  child: Icon(Icons.egg, size: 80, color: Colors.white70),
                ),
              );
            },
          ),
          // Glow effect when holding
          if (widget.isHolding)
            Container(
              width: 160 + (widget.warmth * 40),
              height: 200 + (widget.warmth * 40),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.3 * widget.warmth),
                    blurRadius: 30 + (widget.warmth * 30),
                    spreadRadius: widget.warmth * 15,
                  ),
                ],
              ),
            ),
          // Crack overlays (visual cues at 50%, 65%, 80%)
          if (widget.warmth >= 0.5)
            _CrackOverlay(intensity: _crackIntensity()),
        ],
      ),
    );
  }

  Widget _buildHatchedChibi() {
    return ScaleTransition(
      scale: _hatchScale,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Chibi appears
          Image.asset(
            '${widget.species.spritePrefix}/Jump/${widget.species.framePrefix}Jump_00.png',
            width: 200,
            height: 200,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
            errorBuilder: (context, error, stack) {
              return const Icon(Icons.pets, size: 100, color: Colors.white);
            },
          ),
          const SizedBox(height: 8),
          Text(
            '\u{2764}\uFE0F',
            style: const TextStyle(fontSize: 32),
          ),
        ],
      ),
    );
  }

  int _crackIntensity() {
    if (widget.warmth >= 0.8) return 3;
    if (widget.warmth >= 0.65) return 2;
    return 1;
  }

  Color _eggColor() {
    switch (widget.species) {
      case ChibiSpecies.cat:
        return const Color(0xFFE91E63); // Pink
      case ChibiSpecies.penguin:
        return const Color(0xFF00BCD4); // Cyan
      case ChibiSpecies.panda:
        return const Color(0xFF4CAF50); // Green
    }
  }
}

/// Simple crack overlay drawn with CustomPainter.
class _CrackOverlay extends StatelessWidget {
  final int intensity; // 1, 2, or 3

  const _CrackOverlay({required this.intensity});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 200,
      child: CustomPaint(
        painter: _CrackPainter(intensity),
      ),
    );
  }
}

class _CrackPainter extends CustomPainter {
  final int intensity;

  _CrackPainter(this.intensity);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Simple crack lines that increase with intensity
    if (intensity >= 1) {
      canvas.drawLine(
        Offset(cx - 10, cy - 20),
        Offset(cx + 5, cy + 10),
        paint,
      );
      canvas.drawLine(
        Offset(cx + 5, cy + 10),
        Offset(cx - 5, cy + 30),
        paint,
      );
    }
    if (intensity >= 2) {
      canvas.drawLine(
        Offset(cx + 15, cy - 15),
        Offset(cx + 25, cy + 5),
        paint,
      );
      canvas.drawLine(
        Offset(cx - 20, cy),
        Offset(cx - 30, cy + 20),
        paint,
      );
    }
    if (intensity >= 3) {
      paint.strokeWidth = 3;
      canvas.drawLine(
        Offset(cx - 25, cy - 10),
        Offset(cx + 25, cy - 10),
        paint,
      );
      canvas.drawLine(
        Offset(cx, cy - 30),
        Offset(cx, cy + 30),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CrackPainter oldDelegate) =>
      oldDelegate.intensity != intensity;
}
