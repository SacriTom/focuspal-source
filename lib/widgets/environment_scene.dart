// Full-screen environment background with time-of-day tinting
// and wellbeing brightness/saturation adjustments.
// Uses the home environment sprites (Interior.png / exterior.png)
// or adventure forest backgrounds.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/environment_state.dart';

class EnvironmentScene extends StatelessWidget {
  /// If true, shows adventure forest background instead of home.
  final bool isAdventure;

  const EnvironmentScene({
    super.key,
    this.isAdventure = false,
  });

  @override
  Widget build(BuildContext context) {
    final env = context.watch<EnvironmentState>();

    final String bgAsset = isAdventure
        ? 'assets/environments/adventure/Cartoon_Forest_BG_01.png'
        : 'assets/environments/home/Interior.png';

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        ColorFiltered(
          colorFilter: ColorFilter.matrix(_brightnessMatrix(
            env.wellbeingBrightness,
            env.wellbeingSaturation,
          )),
          child: Image.asset(
            bgAsset,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.none, // Pixel art
            errorBuilder: (context, error, stack) {
              return Container(
                color: _fallbackColor(env.timeOfDay),
              );
            },
          ),
        ),
        // Time-of-day tint overlay
        Container(
          color: Color(env.timeOfDayTint),
        ),
      ],
    );
  }

  /// Builds a colour matrix that adjusts brightness and saturation.
  /// Keeps it simple: brightness multiplies all channels,
  /// saturation interpolates between greyscale and full colour.
  List<double> _brightnessMatrix(double brightness, double saturation) {
    final b = brightness;
    final s = saturation;

    // Luminance weights
    const rw = 0.2126;
    const gw = 0.7152;
    const bw = 0.0722;

    final invSat = 1 - s;

    return [
      (invSat * rw + s) * b, invSat * gw * b, invSat * bw * b, 0, 0,
      invSat * rw * b, (invSat * gw + s) * b, invSat * bw * b, 0, 0,
      invSat * rw * b, invSat * gw * b, (invSat * bw + s) * b, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }

  Color _fallbackColor(ChibiDayPhase timeOfDay) {
    switch (timeOfDay) {
      case ChibiDayPhase.dawn:
        return const Color(0xFFFFF3E0);
      case ChibiDayPhase.morning:
        return const Color(0xFFE3F2FD);
      case ChibiDayPhase.afternoon:
        return const Color(0xFFF1F8E9);
      case ChibiDayPhase.evening:
        return const Color(0xFFFFF8E1);
      case ChibiDayPhase.dusk:
        return const Color(0xFFF3E5F5);
      case ChibiDayPhase.night:
        return const Color(0xFF263238);
    }
  }
}
