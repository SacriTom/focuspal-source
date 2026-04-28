/// Data models for the Chibi creature and related entities.
/// Designed to be character-agnostic: adding a new species requires
/// only a new entry in [ChibiSpecies] and a sprite folder.

enum ChibiSpecies {
  cat,
  penguin,
  panda;

  String get displayName {
    switch (this) {
      case ChibiSpecies.cat:
        return 'Cat';
      case ChibiSpecies.penguin:
        return 'Penguin';
      case ChibiSpecies.panda:
        return 'Panda';
    }
  }

  /// Path prefix for sprite assets. Each species folder follows the
  /// same internal structure (Idle/, Walk/, Jump/, etc.) so the
  /// animation system never needs to know which species it is rendering.
  String get spritePrefix => 'assets/sprites/${name}';

  /// Egg image used on the Choose Chibi and Hatching screens.
  /// Egg 1 (pink/warm) = Cat, Egg 3 (cyan/cool) = Penguin,
  /// Egg 15 (green/natural) = Panda.
  String get eggAsset {
    switch (this) {
      case ChibiSpecies.cat:
        return 'assets/sprites/eggs/1.png';
      case ChibiSpecies.penguin:
        return 'assets/sprites/eggs/3.png';
      case ChibiSpecies.panda:
        return 'assets/sprites/eggs/15.png';
    }
  }

  /// File-name prefix used inside each animation folder.
  /// Cat/Panda use "Characters-Character01-", Penguin uses
  /// "All Characters-Character01-".
  String get framePrefix {
    switch (this) {
      case ChibiSpecies.cat:
        return 'Characters-Character01-';
      case ChibiSpecies.penguin:
        return 'All Characters-Character01-';
      case ChibiSpecies.panda:
        return 'Characters-Character01-';
    }
  }

  /// The "stunned" folder is named differently per species.
  /// Cat and Panda have "Stuned", Penguin has "Confused".
  String get stunnedFolder {
    switch (this) {
      case ChibiSpecies.cat:
        return 'Stuned';
      case ChibiSpecies.penguin:
        return 'Confused';
      case ChibiSpecies.panda:
        return 'Stuned';
    }
  }
}

/// Persisted record of a Chibi. Data model supports multi-Chibi
/// collection (Phase 2) from day one.
class ChibiRecord {
  final String id;
  final ChibiSpecies species;
  String name;
  final DateTime createdAt;
  bool isActive;
  final bool isStarter;
  int totalFocusMinutes;
  int adventuresCompleted;

  ChibiRecord({
    required this.id,
    required this.species,
    required this.name,
    required this.createdAt,
    this.isActive = true,
    this.isStarter = true,
    this.totalFocusMinutes = 0,
    this.adventuresCompleted = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'species': species.name,
        'name': name,
        'created_at': createdAt.toIso8601String(),
        'is_active': isActive ? 1 : 0,
        'is_starter': isStarter ? 1 : 0,
        'total_focus_minutes': totalFocusMinutes,
        'adventures_completed': adventuresCompleted,
      };

  factory ChibiRecord.fromMap(Map<String, dynamic> map) => ChibiRecord(
        id: map['id'] as String,
        species: ChibiSpecies.values.firstWhere(
          (s) => s.name == map['species'],
        ),
        name: map['name'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        isActive: (map['is_active'] as int) == 1,
        isStarter: (map['is_starter'] as int) == 1,
        totalFocusMinutes: map['total_focus_minutes'] as int? ?? 0,
        adventuresCompleted: map['adventures_completed'] as int? ?? 0,
      );
}
