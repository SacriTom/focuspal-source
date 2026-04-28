// Manages active and passive focus sessions.
// Implements design spec Sections 6 and 10.

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/focus_session.dart';
import '../services/storage_service.dart';

class FocusState extends ChangeNotifier {
  FocusSession? _activeSession;
  Timer? _tickTimer;
  bool _isPaused = false;
  int _remainingSeconds = 0;
  int _totalSeconds = 0;

  // ──── Getters ────
  FocusSession? get activeSession => _activeSession;
  bool get hasActiveSession => _activeSession != null;
  bool get isPaused => _isPaused;
  int get remainingSeconds => _remainingSeconds;
  int get totalSeconds => _totalSeconds;
  double get progress =>
      _totalSeconds > 0 ? 1.0 - (_remainingSeconds / _totalSeconds) : 0.0;

  String get remainingFormatted {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Start a new adventure session.
  Future<void> startSession(int durationMinutes) async {
    _activeSession = FocusSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: DateTime.now(),
      durationMinutes: durationMinutes,
    );
    _totalSeconds = durationMinutes * 60;
    _remainingSeconds = _totalSeconds;
    _isPaused = false;
    await StorageService.insertSession(_activeSession!);
    _startTick();
    notifyListeners();
  }

  /// Pause the current adventure.
  void pauseSession() {
    _isPaused = true;
    _tickTimer?.cancel();
    notifyListeners();
  }

  /// Resume a paused adventure.
  void resumeSession() {
    _isPaused = false;
    _startTick();
    notifyListeners();
  }

  /// Abandon the current adventure. No penalty (D-024).
  Future<void> abandonSession() async {
    _tickTimer?.cancel();
    if (_activeSession != null) {
      _activeSession!.endTime = DateTime.now();
      _activeSession!.completed = false;
      await StorageService.updateSession(_activeSession!);
    }
    _activeSession = null;
    _isPaused = false;
    notifyListeners();
  }

  /// Called when timer completes.
  Future<bool> _completeSession() async {
    _tickTimer?.cancel();
    if (_activeSession != null) {
      _activeSession!.endTime = DateTime.now();
      _activeSession!.completed = true;
      await StorageService.updateSession(_activeSession!);
    }
    notifyListeners();
    return true;
  }

  /// Clear completed session state after reward screen.
  void clearCompletedSession() {
    _activeSession = null;
    _remainingSeconds = 0;
    _totalSeconds = 0;
    notifyListeners();
  }

  /// D-037: Reset incomplete adventures at sleep time.
  Future<void> resetForSleepTime() async {
    if (_activeSession != null && !_activeSession!.completed) {
      await abandonSession();
    }
  }

  void _startTick() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      }
      if (_remainingSeconds <= 0) {
        _completeSession();
      }
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }
}
