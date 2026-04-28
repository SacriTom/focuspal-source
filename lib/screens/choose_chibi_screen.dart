// Choose Chibi screen: 3 eggs (Cat/Penguin/Panda).
// Eggs wobble in idle. Selected egg wobbles more vigorously.
// Confirmation bottom sheet before proceeding to hatching.

import 'dart:math';
import 'package:flutter/material.dart';
import '../models/chibi.dart';
import 'hatching_screen.dart';

class ChooseChibiScreen extends StatefulWidget {
  const ChooseChibiScreen({super.key});

  @override
  State<ChooseChibiScreen> createState() => _ChooseChibiScreenState();
}

class _ChooseChibiScreenState extends State<ChooseChibiScreen>
    with TickerProviderStateMixin {
  ChibiSpecies? _selected;
  late List<AnimationController> _wobbleControllers;

  @override
  void initState() {
    super.initState();
    _wobbleControllers = List.generate(3, (i) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 2500 + (i * 300)),
      )..repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    for (final c in _wobbleControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _selectEgg(ChibiSpecies species) {
    setState(() {
      _selected = species;
    });
  }

  void _confirmSelection() {
    if (_selected == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ConfirmSheet(
        species: _selected!,
        onConfirm: () {
          Navigator.of(ctx).pop();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => HatchingScreen(species: _selected!),
            ),
          );
        },
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            const Text(
              'Choose your companion',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Each egg holds a different friend',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
            const Spacer(),
            // Three eggs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ChibiSpecies.values.asMap().entries.map((entry) {
                final i = entry.key;
                final species = entry.value;
                final isSelected = _selected == species;

                return _EggCard(
                  species: species,
                  isSelected: isSelected,
                  wobbleController: _wobbleControllers[i],
                  onTap: () => _selectEgg(species),
                );
              }).toList(),
            ),
            const Spacer(),
            // Confirm button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
              child: AnimatedOpacity(
                opacity: _selected != null ? 1.0 : 0.3,
                duration: const Duration(milliseconds: 300),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _selected != null ? _confirmSelection : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('Hatch this one!'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EggCard extends StatelessWidget {
  final ChibiSpecies species;
  final bool isSelected;
  final AnimationController wobbleController;
  final VoidCallback onTap;

  const _EggCard({
    required this.species,
    required this.isSelected,
    required this.wobbleController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final maxAngle = isSelected ? 5.0 : 2.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: wobbleController,
        builder: (context, child) {
          final angle = sin(wobbleController.value * pi) *
              maxAngle *
              (pi / 180);
          return Transform.rotate(angle: angle, child: child);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: Colors.amber, width: 3)
                : null,
            color: isSelected
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.05),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.7,
                duration: const Duration(milliseconds: 300),
                child: Image.asset(
                  species.eggAsset,
                  width: 80,
                  height: 100,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                  errorBuilder: (context, error, stack) {
                    return Container(
                      width: 80,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Icon(Icons.egg, color: Colors.white54, size: 48),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                species.displayName,
                style: TextStyle(
                  color: isSelected ? Colors.amber : Colors.white70,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmSheet extends StatelessWidget {
  final ChibiSpecies species;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _ConfirmSheet({
    required this.species,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF283593),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            species.eggAsset,
            width: 100,
            height: 120,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
            errorBuilder: (context, error, stack) {
              return const Icon(Icons.egg, size: 80, color: Colors.white54);
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Hatch the ${species.displayName} egg?',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: const Text('Yes!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onCancel,
            child: Text(
              'Wait, let me think',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
