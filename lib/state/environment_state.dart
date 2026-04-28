/// Manages the visual environment state.
/// Implements design spec Section 6 (environment states) and
/// Section 4.1 (time-of-day awareness).

import 'package:flutter/foundation.dart';
import '../models/mood.dart';

/// Three environment wellbeing states from spec Section 6.1.
enum EnvironmentWellbeing { bright, normal, dim }

/// Six time-of-day periods from spec Section 4.1.
enum ChibiDayPhase { dawn, morning, afternoon, evening, dusk, night }

class EnvironmentState extends ChangeNotifier {
  EnvironmentWellbeing _wellbeing = EnvironmentWellbeing.normal;
  ChibiDayPhase _timeOfDay = ChibiDayPhase.morning;

  // Cumulative mood tracking for environment transitions (24hr rolling)
  int _cumulativeAnnoyedMinutes = 0;
  int _cumulativeHappyMinutes = 0;

  EnvironmentWellbeing get wellbeing => _wellbeing;
  ChibiDayPhase get timeOfDay => _timeOfDay;

  /// Update time-of-day based on current real-world time.
  /// Configurable via bedtime/wake settings.
  void updateDayPhase({int? bedtimeHour, int? wakeHour}) {
    final now = DateTime.now();
    final hour = now.hour;
    final bed = bedtimeHour ?? 22;
    final wake = wakeHour ?? 7;

    ChibiDayPhase newTime;
    if (hour >= bed || hour < wake) {
      newTime = ChibiDayPhase.night;
    } else if (hour < wake + 1) {
      newTime = ChibiDayPhase.dawn;
    } else if (hour < 12) {
      newTime = ChibiDayPhase.morning;
    } else if (hour < 17) {
      newTime = ChibiDayPhase.afternoon;
    } else if (hour < 20) {
      newTime = ChibiDayPhase.evening;
    } else {
      newTime = ChibiDayPhase.dusk;
    }

    if (_timeOfDay != newTime) {
      _timeOfDay = newTime;
      notifyListeners();
    }
  }

  /// Track mood time for environment transitions (D-023).
  /// Called periodically (every minute) with the current mood.
  void trackMoodMinute(MoodState mood) {
    if (mood == MoodState.annoyed || mood == MoodState.sad) {
      _cumulativeAnnoyedMinutes++;
    } else if (mood == MoodState.happy || mood == MoodState.ecstatic) {
      _cumulativeHappyMinutes++;
    }

    // Evaluate environment transitions
    _evaluateWellbeing();
  }

  void _evaluateWellbeing() {
    if (_cumulativeAnnoyedMinutes >= 30 &&
        _wellbeing == EnvironmentWellbeing.normal) {
      _wellbeing = EnvironmentWellbeing.dim;
      notifyListeners();
    } else if (_cumulativeHappyMinutes >= 60 &&
        _wellbeing != EnvironmentWellbeing.bright) {
      _wellbeing = EnvironmentWellbeing.bright;
      notifyListeners();
    } else if (_cumulativeHappyMinutes >= 30 &&
        _wellbeing == EnvironmentWellbeing.dim) {
      _wellbeing = EnvironmentWellbeing.normal;
      notifyListeners();
    }
  }

  /// Color overlay for the current time of day.
  /// Returns an ARGB color to tint the environment scene.
  int get timeOfDayTint {
    switch (_timeOfDay) {
      case ChibiDayPhase.dawn:
        return 0x30FFA726; // warm orange
      case ChibiDayPhase.morning:
        return 0x1064B5F6; // slight blue
      case ChibiDayPhase.afternoon:
        return 0x00000000; // no tint
      case ChibiDayPhase.evening:
        return 0x20FFB74D; // golden
      case ChibiDayPhase.dusk:
        return 0x30AB47BC; // purple/amber
      case ChibiDayPhase.night:
        return 0x50263238; // dark blue
    }
  }

  /// Brightness multiplier for wellbeing state.
  double get wellbeingBrightness {
    switch (_wellbeing) {
      case EnvironmentWellbeing.bright:
        return 1.1;
      case EnvironmentWellbeing.normal:
        return 1.0;
      case EnvironmentWellbeing.dim:
        return 0.75;
    }
  }

  /// Saturation multiplier for wellbeing state.
  double get wellbeingSaturation {
    switch (_wellbeing) {
      case EnvironmentWellbeing.bright:
        return 1.2;
      case EnvironmentWellbeing.normal:
        return 1.0;
      case EnvironmentWellbeing.dim:
        return 0.6;
    }
  }
}
