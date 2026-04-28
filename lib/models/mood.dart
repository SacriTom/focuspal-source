// The six mood states from the design spec, ordered most-positive
// to most-negative, plus the special Sleepy state.

enum MoodState {
  ecstatic,
  happy,
  content,
  annoyed,
  sad,
  sleepy;

  String get emoji {
    switch (this) {
      case MoodState.ecstatic:
        return '\u{1F929}'; // star-struck
      case MoodState.happy:
        return '\u{1F60A}'; // smiling
      case MoodState.content:
        return '\u{1F60C}'; // relieved
      case MoodState.annoyed:
        return '\u{1F624}'; // huffing
      case MoodState.sad:
        return '\u{1F622}'; // crying
      case MoodState.sleepy:
        return '\u{1F634}'; // sleeping
    }
  }

  String get label {
    switch (this) {
      case MoodState.ecstatic:
        return 'Ecstatic';
      case MoodState.happy:
        return 'Happy';
      case MoodState.content:
        return 'Content';
      case MoodState.annoyed:
        return 'Annoyed';
      case MoodState.sad:
        return 'Sad';
      case MoodState.sleepy:
        return 'Sleepy';
    }
  }

  /// Which sprite animation maps to this mood for idle display.
  String get idleAnimation {
    switch (this) {
      case MoodState.ecstatic:
        return 'celebrating';
      case MoodState.happy:
        return 'walking';
      case MoodState.content:
        return 'idle';
      case MoodState.annoyed:
        return 'annoyed';
      case MoodState.sad:
        return 'sad';
      case MoodState.sleepy:
        return 'sleeping';
    }
  }

  /// Speech bubble emojis that appear periodically in this mood.
  List<String> get speechEmojis {
    switch (this) {
      case MoodState.ecstatic:
        return ['\u{2B50}', '\u{2728}', '\u{2764}', '\u{1F3C6}'];
      case MoodState.happy:
        return ['\u{1F373}', '\u{1F4D6}', '\u{1F3B5}', '\u{2764}'];
      case MoodState.content:
        return ['\u{1F60C}', '\u{1F4AD}', '\u{1F343}'];
      case MoodState.annoyed:
        return ['\u{2757}', '\u{1F4A8}', '\u{1F4F1}'];
      case MoodState.sad:
        return ['\u{1F4A7}', '\u{1F494}', '\u{1F614}'];
      case MoodState.sleepy:
        return ['\u{1F319}', '\u{2B50}', '\u{1F4A4}'];
    }
  }
}

/// A timestamped mood entry for history tracking.
class MoodEntry {
  final MoodState mood;
  final DateTime timestamp;
  final String? reason;

  const MoodEntry({
    required this.mood,
    required this.timestamp,
    this.reason,
  });

  Map<String, dynamic> toMap() => {
        'mood': mood.name,
        'timestamp': timestamp.toIso8601String(),
        'reason': reason,
      };

  factory MoodEntry.fromMap(Map<String, dynamic> map) => MoodEntry(
        mood: MoodState.values.firstWhere((m) => m.name == map['mood']),
        timestamp: DateTime.parse(map['timestamp'] as String),
        reason: map['reason'] as String?,
      );
}
