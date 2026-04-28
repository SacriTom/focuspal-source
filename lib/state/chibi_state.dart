/// Manages the Chibi's mood, current animation, and lifecycle.
/// Implements the emotion state machine from design spec Section 5.

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chibi.dart';
import '../models/mood.dart';
import '../services/storage_service.dart';
import 'settings_state.dart';

class ChibiState extends ChangeNotifier {
  ChibiRecord? _chibi;
  MoodState _mood = MoodState.content;
  String _currentAnimation = 'idle';
  String? _speechEmoji;
  DateTime? _lastAppOpenTime;
  DateTime? _lastAppBackgroundTime;
  Timer? _moodTimer;
  Timer? _speechBubbleTimer;
  Timer? _interactionTimer;
  bool _isInteracting = false;
  int _interactionSeconds = 0;

  // Reference to settings for mood thresholds
  SettingsState? _settings;

  // ──── Getters ────
  ChibiRecord? get chibi => _chibi;
  MoodState get mood => _mood;
  String get currentAnimation => _currentAnimation;
  String? get speechEmoji => _speechEmoji;
  bool get isInteracting => _isInteracting;
  bool get hasChibi => _chibi != null;

  void setSettings(SettingsState settings) {
    _settings = settings;
  }

  /// Create a new Chibi during onboarding.
  Future<void> createChibi(ChibiSpecies species, String name) async {
    _chibi = ChibiRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      species: species,
      name: name,
      createdAt: DateTime.now(),
    );
    await StorageService.insertChibi(_chibi!);
    _mood = MoodState.happy; // Fresh hatch starts happy
    _currentAnimation = 'idle';
    await StorageService.setCurrentMood(_mood.name);
    await StorageService.insertMoodEntry(
      MoodEntry(mood: _mood, timestamp: DateTime.now(), reason: 'hatched'),
    );
    notifyListeners();
  }

  /// Load existing Chibi from storage.
  Future<void> loadChibi() async {
    _chibi = await StorageService.getActiveChibi();
    if (_chibi != null) {
      final savedMood = StorageService.currentMood;
      if (savedMood != null) {
        _mood = MoodState.values.firstWhere(
          (m) => m.name == savedMood,
          orElse: () => MoodState.content,
        );
      }
      _updateAnimationForMood();
      _startMoodTimer();
      _startSpeechBubbleTimer();
    }
    notifyListeners();
  }

  /// Called when the app comes to the foreground.
  void onAppResumed() {
    _lastAppOpenTime = DateTime.now();

    if (_settings?.isSleepTime ?? false) {
      // D-026: During sleep, log interruption but don't change mood
      _handleSleepInterruption();
      return;
    }

    // Calculate mood based on time away
    if (_lastAppBackgroundTime != null) {
      final awayDuration =
          DateTime.now().difference(_lastAppBackgroundTime!);
      _evaluateMoodOnReturn(awayDuration);
    }

    _startMoodTimer();
    _startSpeechBubbleTimer();
    notifyListeners();
  }

  /// Called when the app goes to the background.
  void onAppPaused() {
    _lastAppBackgroundTime = DateTime.now();
    StorageService.setLastBackgroundTime(
        _lastAppBackgroundTime!.toIso8601String());
    _moodTimer?.cancel();
    _speechBubbleTimer?.cancel();
    _interactionTimer?.cancel();
    _isInteracting = false;
    _speechEmoji = null;
  }

  /// D-027: User taps the Chibi to start interaction window.
  void startInteraction() {
    if (_mood == MoodState.sleepy) return; // Can't play during sleep
    _isInteracting = true;
    _interactionSeconds = 0;
    _currentAnimation = 'heart_react';
    _speechEmoji = '\u{2764}'; // Heart

    _interactionTimer?.cancel();
    _interactionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _interactionSeconds++;

      if (_interactionSeconds == 30) {
        // First tire cue: yawn
        _currentAnimation = 'yawning';
        _speechEmoji = '\u{1F971}'; // Yawning face
      } else if (_interactionSeconds == 45) {
        // Second tire cue: wave
        _currentAnimation = 'waving';
        _speechEmoji = '\u{1F4D6}'; // Book - wants to do own thing
      } else if (_interactionSeconds >= 60) {
        // Settle at 60s cap (D-027): Chibi returns to mood-driven idle
        _isInteracting = false;
        _currentAnimation = _mood.idleAnimation;
        _speechEmoji = null;
        timer.cancel();
      }
      notifyListeners();
    });
    notifyListeners();
  }

  /// Tap during interaction window.
  void onInteractionTap() {
    if (!_isInteracting) return;
    if (_interactionSeconds < 30) {
      _speechEmoji = ['\u{2764}', '\u{2728}', '\u{1F60A}'][
          _interactionSeconds % 3];
      _currentAnimation = 'heart_react';
    }
    notifyListeners();
  }

  /// Set mood directly (used by focus timer for ecstatic on completion).
  Future<void> setMood(MoodState newMood, {String? reason}) async {
    if (_mood == newMood) return;
    _mood = newMood;
    _updateAnimationForMood();
    await StorageService.setCurrentMood(_mood.name);
    await StorageService.insertMoodEntry(
      MoodEntry(mood: _mood, timestamp: DateTime.now(), reason: reason),
    );
    notifyListeners();
  }

  // ──── Private: Mood Logic ────

  /// Tier 1 mood evaluation when app returns to foreground.
  /// Design spec Section 5.4 - Tier 1 mood logic.
  void _evaluateMoodOnReturn(Duration awayDuration) {
    if (_settings == null) return;
    final awayMinutes = awayDuration.inMinutes;

    MoodState newMood;
    String reason;

    if (awayMinutes >= _settings!.ecstaticThreshold) {
      newMood = MoodState.ecstatic;
      reason = 'Long time away (${awayMinutes}min)';
    } else if (awayMinutes >= 15) {
      newMood = MoodState.happy;
      reason = 'Good break (${awayMinutes}min)';
    } else if (awayMinutes >= _settings!.recoveryTime) {
      newMood = MoodState.content;
      reason = 'Short break (${awayMinutes}min)';
    } else {
      // Came back too soon -- mood depends on how long app stays open
      newMood = _mood; // Keep current, timer will evaluate
      reason = 'Quick return';
    }

    if (newMood != _mood) {
      setMood(newMood, reason: reason);
    }
  }

  /// Periodic check while app is in foreground.
  /// App being open counts as "phone use" for Tier 1.
  void _startMoodTimer() {
    _moodTimer?.cancel();
    _moodTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_settings == null || _chibi == null) return;
      if (_settings!.isSleepTime) {
        if (_mood != MoodState.sleepy) {
          setMood(MoodState.sleepy, reason: 'Bedtime');
        }
        return;
      }

      // Time the app has been open continuously
      if (_lastAppOpenTime == null) return;
      final openMinutes =
          DateTime.now().difference(_lastAppOpenTime!).inMinutes;

      if (openMinutes >= _settings!.timeToAnnoyance +
              _settings!.annoyanceEscalation &&
          _mood != MoodState.sad) {
        setMood(MoodState.sad, reason: 'Extended phone use');
      } else if (openMinutes >= _settings!.timeToAnnoyance &&
          _mood != MoodState.annoyed &&
          _mood != MoodState.sad) {
        setMood(MoodState.annoyed, reason: 'Phone use too long');
      }
    });
  }

  /// Speech bubbles appear every 15-30 seconds during idle viewing.
  void _startSpeechBubbleTimer() {
    _speechBubbleTimer?.cancel();
    _speechBubbleTimer =
        Timer.periodic(const Duration(seconds: 20), (_) {
      if (_isInteracting) return;
      final emojis = _mood.speechEmojis;
      if (emojis.isEmpty) return;
      _speechEmoji =
          emojis[DateTime.now().millisecondsSinceEpoch % emojis.length];
      notifyListeners();

      // Clear after 4 seconds
      Future.delayed(const Duration(seconds: 4), () {
        _speechEmoji = null;
        notifyListeners();
      });
    });
  }

  void _handleSleepInterruption() {
    if (_mood != MoodState.sleepy) {
      setMood(MoodState.sleepy, reason: 'Sleep time');
    }
    // Bank the interruption for morning mood calculation
    final current = StorageService.nightDisturbances;
    StorageService.setNightDisturbances(current + 1);
  }

  void _updateAnimationForMood() {
    if (!_isInteracting) {
      _currentAnimation = _mood.idleAnimation;
    }
  }

  /// Check sleep/wake transition. Called periodically or on app resume.
  Future<void> checkTimeOfDay() async {
    if (_settings == null || _chibi == null) return;

    if (_settings!.isSleepTime && _mood != MoodState.sleepy) {
      await setMood(MoodState.sleepy, reason: 'Bedtime');
    } else if (!_settings!.isSleepTime && _mood == MoodState.sleepy) {
      // Morning! Calculate mood from night disturbances (D-026)
      await _handleMorningWakeUp();
    }
  }

  Future<void> _handleMorningWakeUp() async {
    final disturbances = StorageService.nightDisturbances;
    MoodState morningMood;

    if (disturbances == 0) {
      // Good night: one level up from pre-sleep
      morningMood = MoodState.happy;
    } else if (disturbances <= 2) {
      morningMood = MoodState.content;
    } else if (disturbances <= 5) {
      morningMood = MoodState.annoyed;
    } else {
      morningMood = MoodState.annoyed; // Floor: never start at Sad
    }

    await StorageService.setNightDisturbances(0);
    await setMood(morningMood, reason: 'Morning wake-up ($disturbances disturbances)');
    _currentAnimation = 'waking_up';
    notifyListeners();

    // After wake-up animation, switch to mood idle
    Future.delayed(const Duration(seconds: 3), () {
      _updateAnimationForMood();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _moodTimer?.cancel();
    _speechBubbleTimer?.cancel();
    _interactionTimer?.cancel();
    super.dispose();
  }
}
