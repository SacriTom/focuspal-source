// Full-screen environment background.
// Adventure mode: forest PNG.
// Home mode (A1): cozy time-of-day gradient instead of the previous
// Interior.png. The latter is a furniture sprite-atlas, not a composed
// room scene; stretching it as a background read as visual clutter.

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

    if (isAdventure) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ColorFiltered(
            colorFilter: ColorFilter.matrix(_brightnessMatrix(
              env.wellbeingBrightness,
              env.wellbeingSaturation,
            )),
            child: Image.asset(
              'assets/environments/adventure/Cartoon_Forest_BG_01.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.none,
              errorBuilder: (context, error, stack) {
                return Container(color: _fallbackColor(env.timeOfDay));
              },
            ),
          ),
          Container(color: Color(env.timeOfDayTint)),
        ],
      );
    }

    // Home: cozy gradient that shifts with time-of-day. No sprite atlas.
    final palette = _homePalette(env.timeOfDay);
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: palette,
            ),
          ),
        ),
        // Soft warm horizon stripe so the lower half reads as a floor area
        // rather than empty space  helps the Chibi feel grounded.
        Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            widthFactor: 1.0,
            heightFactor: 0.3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    palette.last.withValues(alpha: 0.0),
                    palette.last.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
          ),
        ),
        Container(color: Color(env.timeOfDayTint)),
      ],
    );
  }

  /// Two-stop gradient per time-of-day, cozy / warm rather than busy.
  List<Color> _homePalette(ChibiDayPhase phase) {
    switch (phase) {
      case ChibiDayPhase.dawn:
        return const [Color(0xFF3E3160), Color(0xFFFFB689)];
      case ChibiDayPhase.morning:
        return const [Color(0xFF4A6FA5), Color(0xFFFFE4B5)];
      case ChibiDayPhase.afternoon:
        return const [Color(0xFF5B7CAA), Color(0xFFFFEEC9)];
      case ChibiDayPhase.evening:
        return const [Color(0xFF3D5A80), Color(0xFFEE9B5C)];
      case ChibiDayPhase.dusk:
        return const [Color(0xFF2C3E66), Color(0xFFAB6BB5)];
      case ChibiDayPhase.night:
        return const [Color(0xFF0F1A35), Color(0xFF2E3F66)];
    }
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
