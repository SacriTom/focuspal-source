/// Character-agnostic sprite loading service.
/// Adding a new species requires only a new sprite folder and enum value --
/// zero changes to this file.

import '../models/chibi.dart';

/// Describes one animation sequence: ordered frames, playback speed, looping.
class SpriteAnimation {
  final List<String> framePaths;
  final int fps;
  final bool loop;

  const SpriteAnimation({
    required this.framePaths,
    this.fps = 8,
    this.loop = true,
  });
}

/// Maps logical animation names to sprite folder names and frame counts.
/// The design spec (Section 9.2) defines these mappings.
class SpriteService {
  /// Cache: species -> animationName -> SpriteAnimation
  static final Map<ChibiSpecies, Map<String, SpriteAnimation>> _cache = {};

  /// Gets the animation for a given species and logical animation name.
  /// Uses the mapping from the design spec Section 9.2.
  static SpriteAnimation getAnimation(
    ChibiSpecies species,
    String animationName,
  ) {
    _cache[species] ??= {};
    if (_cache[species]!.containsKey(animationName)) {
      return _cache[species]![animationName]!;
    }

    final mapping = _getMapping(species, animationName);
    _cache[species]![animationName] = mapping;
    return mapping;
  }

  /// Pre-caches all animations for a species. Call during loading.
  static void preloadSpecies(ChibiSpecies species) {
    for (final name in allAnimationNames) {
      getAnimation(species, name);
    }
  }

  static const allAnimationNames = [
    'idle',
    'walking',
    'sleeping',
    'celebrating',
    'annoyed',
    'sad',
    'cooking',
    'reading',
    'playing_music',
    'hatching',
    'waking_up',
    'yawning',
    'waving',
    'heart_react',
    'adventuring',
  ];

  static SpriteAnimation _getMapping(
    ChibiSpecies species,
    String animationName,
  ) {
    final prefix = species.spritePrefix;
    final filePrefix = species.framePrefix;

    switch (animationName) {
      case 'idle':
        return _buildAnimation(
          prefix, 'Idle', filePrefix, 'Idle', 20,
          fps: 8, loop: true,
        );
      case 'walking':
        return _buildAnimation(
          prefix, 'Walk', filePrefix, 'Walk',
          _walkFrameCount(species),
          fps: 10, loop: true,
        );
      case 'sleeping':
        // Idle at reduced FPS for sleepy feel
        return _buildAnimation(
          prefix, 'Idle', filePrefix, 'Idle', 20,
          fps: 3, loop: true,
        );
      case 'celebrating':
        // Jump animation for celebration
        return _buildAnimation(
          prefix, 'Jump', filePrefix, 'Jump', 20,
          fps: 10, loop: true,
        );
      case 'annoyed':
        // Hit animation, hold last frame
        return _buildAnimation(
          prefix, 'Hit', filePrefix, 'Hit',
          _hitFrameCount(species),
          fps: 6, loop: false,
        );
      case 'sad':
        // Stuned/Confused animation, hold last frame
        return _buildAnimation(
          prefix, species.stunnedFolder, filePrefix,
          species == ChibiSpecies.penguin ? 'Confused' : 'Stuned',
          24,
          fps: 4, loop: false,
        );
      case 'cooking':
        // Walk stationary with overlay
        return _buildAnimation(
          prefix, 'Walk', filePrefix, 'Walk',
          _walkFrameCount(species),
          fps: 8, loop: true,
        );
      case 'reading':
        return _buildAnimation(
          prefix, 'Idle', filePrefix, 'Idle', 20,
          fps: 6, loop: true,
        );
      case 'playing_music':
        return _buildAnimation(
          prefix, 'Idle', filePrefix, 'Idle', 20,
          fps: 6, loop: true,
        );
      case 'hatching':
        return _buildAnimation(
          prefix, 'Jump', filePrefix, 'Jump', 20,
          fps: 10, loop: false,
        );
      case 'waking_up':
        return _buildAnimation(
          prefix, 'Jump', filePrefix, 'Jump', 20,
          fps: 6, loop: false,
        );
      case 'yawning':
        return _buildAnimation(
          prefix, 'Idle', filePrefix, 'Idle', 20,
          fps: 4, loop: false,
        );
      case 'waving':
        // First half of throwing
        return _buildAnimation(
          prefix, 'Throwing', filePrefix, 'Throwing',
          _throwingFrameCount(species) ~/ 2,
          fps: 8, loop: false,
        );
      case 'heart_react':
        return _buildAnimation(
          prefix, 'Jump', filePrefix, 'Jump', 20,
          fps: 10, loop: false,
        );
      case 'adventuring':
        return _buildAnimation(
          prefix, 'Walk', filePrefix, 'Walk',
          _walkFrameCount(species),
          fps: 10, loop: true,
        );
      default:
        // Fallback to idle
        return _buildAnimation(
          prefix, 'Idle', filePrefix, 'Idle', 20,
          fps: 8, loop: true,
        );
    }
  }

  static int _walkFrameCount(ChibiSpecies species) {
    switch (species) {
      case ChibiSpecies.cat:
        return 20;
      case ChibiSpecies.penguin:
        return 30;
      case ChibiSpecies.panda:
        return 30;
    }
  }

  static int _hitFrameCount(ChibiSpecies species) {
    switch (species) {
      case ChibiSpecies.cat:
        return 50;
      case ChibiSpecies.penguin:
        return 35;
      case ChibiSpecies.panda:
        return 45;
    }
  }

  static int _throwingFrameCount(ChibiSpecies species) {
    switch (species) {
      case ChibiSpecies.cat:
        return 40;
      case ChibiSpecies.penguin:
        return 35;
      case ChibiSpecies.panda:
        return 35;
    }
  }

  /// Builds a SpriteAnimation with ordered frame paths.
  /// Frame naming: "{filePrefix}{animName}_{nn}.png" where nn is zero-padded
  /// except for Roll which uses single digits.
  static SpriteAnimation _buildAnimation(
    String speciesPrefix,
    String folderName,
    String filePrefix,
    String animName,
    int frameCount, {
    required int fps,
    required bool loop,
  }) {
    final frames = <String>[];
    for (int i = 0; i < frameCount; i++) {
      // Roll uses single-digit naming (Roll_0, Roll_1, etc.)
      // Others use zero-padded (Idle_00, Idle_01, etc.)
      final frameNum = (folderName == 'Roll') ? '$i' : i.toString().padLeft(2, '0');
      frames.add('$speciesPrefix/$folderName/${filePrefix}${animName}_$frameNum.png');
    }
    return SpriteAnimation(framePaths: frames, fps: fps, loop: loop);
  }
}
