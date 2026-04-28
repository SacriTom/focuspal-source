// Hatching screen: Hold finger on egg to warm it.
// Max 60 seconds (D-035). Warmth meter fills while holding,
// drains slowly when released. Egg wobbles, cracks, Chibi emerges.

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chibi.dart';
import '../widgets/egg_animation.dart';
import '../widgets/warmth_meter.dart';
import 'naming_screen.dart';

class HatchingScreen extends StatefulWidget {
  final ChibiSpecies species;

  const HatchingScreen({super.key, required this.species});

  @override
  State<HatchingScreen> createState() => _HatchingScreenState();
}

class _HatchingScreenState extends State<HatchingScreen> {
  double _warmth = 0.0;
  bool _isHolding = false;
  bool _hatched = false;
  bool _showInstruction = true;
  Timer? _warmthTimer;

  // Max 60 seconds = warmth fills at ~1.67% per second
  static const double _warmthPerTick = 0.0167;
  // Drain rate when not holding: ~1% per second
  static const double _drainPerTick = 0.01;
  static const _tickInterval = Duration(milliseconds: 100);

  @override
  void dispose() {
    _warmthTimer?.cancel();
    super.dispose();
  }

  void _startHolding() {
    if (_hatched) return;
    setState(() {
      _isHolding = true;
      _showInstruction = false;
    });
    _warmthTimer?.cancel();
    _warmthTimer = Timer.periodic(_tickInterval, (_) {
      if (!_isHolding || _hatched) return;
      setState(() {
        _warmth = (_warmth + _warmthPerTick / 10).clamp(0.0, 1.0);
        if (_warmth >= 1.0) {
          _hatch();
        }
      });
    });
  }

  void _stopHolding() {
    if (_hatched) return;
    setState(() => _isHolding = false);
    _warmthTimer?.cancel();
    // Start draining
    _warmthTimer = Timer.periodic(_tickInterval, (_) {
      if (_isHolding || _hatched) return;
      setState(() {
        _warmth = (_warmth - _drainPerTick / 10).clamp(0.0, 1.0);
      });
      if (_warmth <= 0.0) {
        _warmthTimer?.cancel();
      }
    });
  }

  void _hatch() {
    _warmthTimer?.cancel();
    setState(() {
      _hatched = true;
      _isHolding = false;
    });
    // Navigate after hatch animation
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => NamingScreen(species: widget.species),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            // Egg / hatched Chibi
            GestureDetector(
              onTapDown: (_) => _startHolding(),
              onTapUp: (_) => _stopHolding(),
              onTapCancel: _stopHolding,
              onLongPressStart: (_) => _startHolding(),
              onLongPressEnd: (_) => _stopHolding(),
              child: EggAnimation(
                species: widget.species,
                warmth: _warmth,
                hatched: _hatched,
                isHolding: _isHolding,
              ),
            ),
            const SizedBox(height: 32),
            // Warmth meter
            if (!_hatched)
              WarmthMeter(progress: _warmth),
            if (_hatched)
              const Text(
                'Welcome to the world!',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const Spacer(),
            // Instruction text
            AnimatedOpacity(
              opacity: _showInstruction && !_hatched ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: Text(
                  'Hold to warm your egg',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            if (!_showInstruction && !_hatched && !_isHolding && _warmth > 0 && _warmth < 1.0)
              Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    'Your egg is getting cold...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            if (_showInstruction || _isHolding || _hatched || _warmth <= 0)
              const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
