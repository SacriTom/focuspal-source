/// Animated sprite renderer. Loads PNG frame sequences and plays them
/// at the specified frame rate. Character-agnostic: just feed it paths.

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chibi.dart';
import '../services/sprite_service.dart';

class ChibiSpriteWidget extends StatefulWidget {
  final ChibiSpecies species;
  final String animationName;
  final double width;
  final double height;
  final bool flipHorizontal;

  const ChibiSpriteWidget({
    super.key,
    required this.species,
    required this.animationName,
    this.width = 200,
    this.height = 200,
    this.flipHorizontal = false,
  });

  @override
  State<ChibiSpriteWidget> createState() => _ChibiSpriteWidgetState();
}

class _ChibiSpriteWidgetState extends State<ChibiSpriteWidget> {
  int _currentFrame = 0;
  Timer? _frameTimer;
  late SpriteAnimation _animation;

  @override
  void initState() {
    super.initState();
    _loadAnimation();
  }

  @override
  void didUpdateWidget(ChibiSpriteWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animationName != widget.animationName ||
        oldWidget.species != widget.species) {
      _loadAnimation();
    }
  }

  void _loadAnimation() {
    _frameTimer?.cancel();
    _animation = SpriteService.getAnimation(
      widget.species,
      widget.animationName,
    );
    _currentFrame = 0;

    if (_animation.framePaths.isEmpty) return;

    final interval = Duration(
      milliseconds: (1000 / _animation.fps).round(),
    );

    _frameTimer = Timer.periodic(interval, (_) {
      if (!mounted) return;
      setState(() {
        if (_animation.loop) {
          _currentFrame =
              (_currentFrame + 1) % _animation.framePaths.length;
        } else {
          if (_currentFrame < _animation.framePaths.length - 1) {
            _currentFrame++;
          }
          // Hold on last frame if not looping
        }
      });
    });
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_animation.framePaths.isEmpty) {
      return SizedBox(width: widget.width, height: widget.height);
    }

    final framePath = _animation.framePaths[_currentFrame];

    Widget image = Image.asset(
      framePath,
      width: widget.width,
      height: widget.height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none, // Pixel art: nearest-neighbor
      errorBuilder: (context, error, stack) {
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: const Center(
            child: Icon(Icons.pets, size: 48, color: Colors.white70),
          ),
        );
      },
    );

    if (widget.flipHorizontal) {
      image = Transform.flip(flipX: true, child: image);
    }

    return image;
  }
}
