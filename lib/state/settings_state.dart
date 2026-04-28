/// Manages sensitivity presets and user preferences.
/// Implements D-025 (presets), D-036 (relaxed minimums), sleep schedule.

import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';

/// Named presets from the design spec Section 5.3.
enum SensitivityPreset {
  relaxed,
  focusFriendly,
  superFocused;

  String get displayName {
    switch (this) {
      case SensitivityPreset.relaxed:
        return 'Relaxed';
      case SensitivityPreset.focusFriendly:
        return 'Focus-Friendly';
      case SensitivityPreset.superFocused:
        return 'Super-Focused';
    }
  }

  String get description {
    switch (this) {
      case SensitivityPreset.relaxed:
        return "I'm pretty chill about phone time";
      case SensitivityPreset.focusFriendly:
        return 'A nice balance between us';
      case SensitivityPreset.superFocused:
        return 'I take focus very seriously!';
    }
  }

  String get storageKey {
    switch (this) {
      case SensitivityPreset.relaxed:
        return 'relaxed';
      case SensitivityPreset.focusFriendly:
        return 'focus_friendly';
      case SensitivityPreset.superFocused:
        return 'super_focused';
    }
  }

  /// Default parameter values per preset (from design spec Table).
  Map<String, int> get defaults {
    switch (this) {
      case SensitivityPreset.relaxed:
        return {
          'time_to_annoyance': 45,
          'recovery_time': 3,
          'ecstatic_threshold': 30,
          'annoyance_escalation': 20,
        };
      case SensitivityPreset.focusFriendly:
        return {
          'time_to_annoyance': 20,
          'recovery_time': 5,
          'ecstatic_threshold': 60,
          'annoyance_escalation': 10,
        };
      case SensitivityPreset.superFocused:
        return {
          'time_to_annoyance': 10,
          'recovery_time': 10,
          'ecstatic_threshold': 120,
          'annoyance_escalation': 5,
        };
    }
  }
}

class SettingsState extends ChangeNotifier {
  SensitivityPreset _preset = SensitivityPreset.focusFriendly;
  int _timeToAnnoyance = 20;
  int _recoveryTime = 5;
  int _ecstaticThreshold = 60;
  int _annoyanceEscalation = 10;
  int _bedtimeHour = 22;
  int _bedtimeMinute = 0;
  int _wakeHour = 7;
  int _wakeMinute = 0;
  bool _tier2Enabled = false;

  // ──── D-036: Hard-coded minimums for Relaxed preset ────
  static const Map<String, int> relaxedMinimums = {
    'time_to_annoyance': 30,
    'recovery_time': 2,
    'ecstatic_threshold': 20,
    'annoyance_escalation': 10,
  };

  // ──── Getters ────
  SensitivityPreset get preset => _preset;
  int get timeToAnnoyance => _timeToAnnoyance;
  int get recoveryTime => _recoveryTime;
  int get ecstaticThreshold => _ecstaticThreshold;
  int get annoyanceEscalation => _annoyanceEscalation;
  int get bedtimeHour => _bedtimeHour;
  int get bedtimeMinute => _bedtimeMinute;
  int get wakeHour => _wakeHour;
  int get wakeMinute => _wakeMinute;
  bool get tier2Enabled => _tier2Enabled;

  /// Load persisted settings.
  void loadFromStorage() {
    final presetKey = StorageService.selectedPreset;
    _preset = SensitivityPreset.values.firstWhere(
      (p) => p.storageKey == presetKey,
      orElse: () => SensitivityPreset.focusFriendly,
    );
    _timeToAnnoyance = StorageService.timeToAnnoyance;
    _recoveryTime = StorageService.recoveryTime;
    _ecstaticThreshold = StorageService.ecstaticThreshold;
    _annoyanceEscalation = StorageService.annoyanceEscalation;
    _bedtimeHour = StorageService.bedtimeHour;
    _bedtimeMinute = StorageService.bedtimeMinute;
    _wakeHour = StorageService.wakeHour;
    _wakeMinute = StorageService.wakeMinute;
    _tier2Enabled = StorageService.tier2Enabled;
    notifyListeners();
  }

  /// Apply a named preset and persist.
  Future<void> setPreset(SensitivityPreset preset) async {
    _preset = preset;
    final defaults = preset.defaults;
    _timeToAnnoyance = defaults['time_to_annoyance']!;
    _recoveryTime = defaults['recovery_time']!;
    _ecstaticThreshold = defaults['ecstatic_threshold']!;
    _annoyanceEscalation = defaults['annoyance_escalation']!;
    await _persistAll();
    notifyListeners();
  }

  /// Set individual parameter with D-036 minimum enforcement.
  Future<void> setTimeToAnnoyanceValue(int v) async {
    _timeToAnnoyance = _enforceMinimum('time_to_annoyance', v);
    await StorageService.setTimeToAnnoyance(_timeToAnnoyance);
    notifyListeners();
  }

  Future<void> setRecoveryTimeValue(int v) async {
    _recoveryTime = _enforceMinimum('recovery_time', v);
    await StorageService.setRecoveryTime(_recoveryTime);
    notifyListeners();
  }

  Future<void> setEcstaticThresholdValue(int v) async {
    _ecstaticThreshold = _enforceMinimum('ecstatic_threshold', v);
    await StorageService.setEcstaticThreshold(_ecstaticThreshold);
    notifyListeners();
  }

  Future<void> setAnnoyanceEscalationValue(int v) async {
    _annoyanceEscalation = _enforceMinimum('annoyance_escalation', v);
    await StorageService.setAnnoyanceEscalation(_annoyanceEscalation);
    notifyListeners();
  }

  Future<void> setBedtime(int hour, int minute) async {
    _bedtimeHour = hour;
    _bedtimeMinute = minute;
    await StorageService.setBedtime(hour, minute);
    notifyListeners();
  }

  Future<void> setWakeTime(int hour, int minute) async {
    _wakeHour = hour;
    _wakeMinute = minute;
    await StorageService.setWakeTime(hour, minute);
    notifyListeners();
  }

  Future<void> setTier2Enabled(bool v) async {
    _tier2Enabled = v;
    await StorageService.setTier2Enabled(v);
    notifyListeners();
  }

  /// Check if we are currently in the sleep window.
  bool get isSleepTime {
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final bedMinutes = _bedtimeHour * 60 + _bedtimeMinute;
    final wakeMinutes = _wakeHour * 60 + _wakeMinute;

    if (bedMinutes > wakeMinutes) {
      // Sleep crosses midnight (e.g., 22:00 - 07:00)
      return nowMinutes >= bedMinutes || nowMinutes < wakeMinutes;
    } else {
      return nowMinutes >= bedMinutes && nowMinutes < wakeMinutes;
    }
  }

  // ──── Private helpers ────

  int _enforceMinimum(String param, int value) {
    if (_preset == SensitivityPreset.relaxed) {
      final min = relaxedMinimums[param];
      if (min != null && value < min) return min;
    }
    return value.clamp(1, 999);
  }

  Future<void> _persistAll() async {
    await StorageService.setPreset(_preset.storageKey);
    await StorageService.setTimeToAnnoyance(_timeToAnnoyance);
    await StorageService.setRecoveryTime(_recoveryTime);
    await StorageService.setEcstaticThreshold(_ecstaticThreshold);
    await StorageService.setAnnoyanceEscalation(_annoyanceEscalation);
  }
}
