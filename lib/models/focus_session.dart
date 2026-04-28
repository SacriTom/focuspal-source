/// Represents a completed or in-progress focus session (adventure).

class FocusSession {
  final String id;
  final DateTime startTime;
  final int durationMinutes;
  DateTime? endTime;
  bool completed;
  bool paused;

  FocusSession({
    required this.id,
    required this.startTime,
    required this.durationMinutes,
    this.endTime,
    this.completed = false,
    this.paused = false,
  });

  Duration get elapsed {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  Duration get remaining {
    final total = Duration(minutes: durationMinutes);
    final e = elapsed;
    if (e >= total) return Duration.zero;
    return total - e;
  }

  double get progress {
    final total = Duration(minutes: durationMinutes).inSeconds;
    if (total == 0) return 1.0;
    final e = elapsed.inSeconds;
    return (e / total).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'start_time': startTime.toIso8601String(),
        'duration_minutes': durationMinutes,
        'end_time': endTime?.toIso8601String(),
        'completed': completed ? 1 : 0,
        'paused': paused ? 1 : 0,
      };

  factory FocusSession.fromMap(Map<String, dynamic> map) => FocusSession(
        id: map['id'] as String,
        startTime: DateTime.parse(map['start_time'] as String),
        durationMinutes: map['duration_minutes'] as int,
        endTime: map['end_time'] != null
            ? DateTime.parse(map['end_time'] as String)
            : null,
        completed: (map['completed'] as int) == 1,
        paused: (map['paused'] as int) == 1,
      );
}
