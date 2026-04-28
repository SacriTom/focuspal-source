// Hold-to-warm progress bar for the incubation / hatching screen.
// Fills while user holds finger on egg. Max 60 seconds (D-035).
// Drains slowly when released (~1% per second).

import 'package:flutter/material.dart';

class WarmthMeter extends StatelessWidget {
  /// 0.0 to 1.0
  final double progress;

  const WarmthMeter({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    // Colour transitions from cool blue to warm amber to hot orange
    final color = ColorTween(
      begin: const Color(0xFF90CAF9),
      end: const Color(0xFFFF6D00),
    ).lerp(progress) ?? const Color(0xFFFFAB40);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress bar
        Container(
          height: 16,
          width: 240,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: 236 * progress,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.8),
                      color,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${(progress * 100).toInt()}%',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
