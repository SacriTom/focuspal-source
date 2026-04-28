// Local persistence layer.
// SharedPreferences for settings, SQLite for Chibi state and history.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/chibi.dart';
import '../models/mood.dart';
import '../models/focus_session.dart';

class StorageService {
  static Database? _db;
  static SharedPreferences? _prefs;

  // ──────────────────────────── Init ────────────────────────────

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    if (kIsWeb) return;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dbPath, 'focuspal.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE chibi (
            id TEXT PRIMARY KEY,
            species TEXT NOT NULL,
            name TEXT NOT NULL,
            created_at TEXT NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 1,
            is_starter INTEGER NOT NULL DEFAULT 1,
            total_focus_minutes INTEGER NOT NULL DEFAULT 0,
            adventures_completed INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE mood_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            mood TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            reason TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE focus_sessions (
            id TEXT PRIMARY KEY,
            start_time TEXT NOT NULL,
            duration_minutes INTEGER NOT NULL,
            end_time TEXT,
            completed INTEGER NOT NULL DEFAULT 0,
            paused INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  // ──────────────────────── SharedPreferences ──────────────────────

  static bool get onboardingComplete =>
      _prefs?.getBool('onboarding_complete') ?? false;

  static Future<void> setOnboardingComplete(bool v) async =>
      await _prefs?.setBool('onboarding_complete', v);

  static String get selectedPreset =>
      _prefs?.getString('preset') ?? 'focus_friendly';

  static Future<void> setPreset(String v) async =>
      await _prefs?.setString('preset', v);

  static int get timeToAnnoyance =>
      _prefs?.getInt('time_to_annoyance') ?? 20;

  static Future<void> setTimeToAnnoyance(int v) async =>
      await _prefs?.setInt('time_to_annoyance', v);

  static int get recoveryTime =>
      _prefs?.getInt('recovery_time') ?? 5;

  static Future<void> setRecoveryTime(int v) async =>
      await _prefs?.setInt('recovery_time', v);

  static int get ecstaticThreshold =>
      _prefs?.getInt('ecstatic_threshold') ?? 60;

  static Future<void> setEcstaticThreshold(int v) async =>
      await _prefs?.setInt('ecstatic_threshold', v);

  static int get annoyanceEscalation =>
      _prefs?.getInt('annoyance_escalation') ?? 10;

  static Future<void> setAnnoyanceEscalation(int v) async =>
      await _prefs?.setInt('annoyance_escalation', v);

  static int get bedtimeHour => _prefs?.getInt('bedtime_hour') ?? 22;
  static int get bedtimeMinute => _prefs?.getInt('bedtime_minute') ?? 0;
  static int get wakeHour => _prefs?.getInt('wake_hour') ?? 7;
  static int get wakeMinute => _prefs?.getInt('wake_minute') ?? 0;

  static Future<void> setBedtime(int hour, int minute) async {
    await _prefs?.setInt('bedtime_hour', hour);
    await _prefs?.setInt('bedtime_minute', minute);
  }

  static Future<void> setWakeTime(int hour, int minute) async {
    await _prefs?.setInt('wake_hour', hour);
    await _prefs?.setInt('wake_minute', minute);
  }

  static bool get tier2Enabled =>
      _prefs?.getBool('tier2_enabled') ?? false;

  static Future<void> setTier2Enabled(bool v) async =>
      await _prefs?.setBool('tier2_enabled', v);

  static String? get currentMood => _prefs?.getString('current_mood');

  static Future<void> setCurrentMood(String mood) async =>
      await _prefs?.setString('current_mood', mood);

  static String? get lastBackgroundTime =>
      _prefs?.getString('last_background_time');

  static Future<void> setLastBackgroundTime(String iso) async =>
      await _prefs?.setString('last_background_time', iso);

  static int get nightDisturbances =>
      _prefs?.getInt('night_disturbances') ?? 0;

  static Future<void> setNightDisturbances(int v) async =>
      await _prefs?.setInt('night_disturbances', v);

  // ──────────────────────── SQLite: Chibi ──────────────────────

  static Future<void> insertChibi(ChibiRecord chibi) async {
    await _db?.insert('chibi', chibi.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<ChibiRecord?> getActiveChibi() async {
    final results = await _db?.query('chibi',
        where: 'is_active = ?', whereArgs: [1], limit: 1);
    if (results == null || results.isEmpty) return null;
    return ChibiRecord.fromMap(results.first);
  }

  static Future<void> updateChibi(ChibiRecord chibi) async {
    await _db?.update('chibi', chibi.toMap(),
        where: 'id = ?', whereArgs: [chibi.id]);
  }

  // ──────────────────────── SQLite: Mood History ──────────────────

  static Future<void> insertMoodEntry(MoodEntry entry) async {
    await _db?.insert('mood_history', entry.toMap());
  }

  static Future<List<MoodEntry>> getMoodHistory({int limit = 100}) async {
    final results = await _db?.query('mood_history',
        orderBy: 'timestamp DESC', limit: limit);
    if (results == null) return [];
    return results.map((m) => MoodEntry.fromMap(m)).toList();
  }

  // ──────────────────────── SQLite: Focus Sessions ──────────────────

  static Future<void> insertSession(FocusSession session) async {
    await _db?.insert('focus_sessions', session.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateSession(FocusSession session) async {
    await _db?.update('focus_sessions', session.toMap(),
        where: 'id = ?', whereArgs: [session.id]);
  }

  static Future<List<FocusSession>> getCompletedSessions({
    int limit = 50,
  }) async {
    final results = await _db?.query('focus_sessions',
        where: 'completed = ?',
        whereArgs: [1],
        orderBy: 'start_time DESC',
        limit: limit);
    if (results == null) return [];
    return results.map((m) => FocusSession.fromMap(m)).toList();
  }

  static Future<int> getStreak() async {
    final sessions = await getCompletedSessions(limit: 365);
    if (sessions.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = DateTime.now();

    for (int day = 0; day < 365; day++) {
      final date = checkDate.subtract(Duration(days: day));
      final hasSession = sessions.any((s) =>
          s.startTime.year == date.year &&
          s.startTime.month == date.month &&
          s.startTime.day == date.day);
      if (hasSession) {
        streak++;
      } else if (day > 0) {
        break;
      }
    }
    return streak;
  }

  static Future<int> getTodayFocusMinutes() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final results = await _db?.query('focus_sessions',
        where: 'completed = ? AND start_time >= ?',
        whereArgs: [1, todayStart.toIso8601String()]);
    if (results == null) return 0;
    int total = 0;
    for (final r in results) {
      total += r['duration_minutes'] as int;
    }
    return total;
  }
}
