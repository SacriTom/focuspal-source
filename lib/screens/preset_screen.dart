// Preset selection screen: 3 cards (Relaxed / Focus-Friendly / Super-Focused).
// Each shows sensitivity description. Tap to select.
// D-036: Hard-coded minimums on Relaxed.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/chibi_state.dart';
import '../state/settings_state.dart';
import '../widgets/chibi_sprite.dart';
import 'tier2_nudge_screen.dart';

class PresetScreen extends StatefulWidget {
  const PresetScreen({super.key});

  @override
  State<PresetScreen> createState() => _PresetScreenState();
}

class _PresetScreenState extends State<PresetScreen> {
  SensitivityPreset _selected = SensitivityPreset.focusFriendly;

  void _confirm() async {
    final settings = context.read<SettingsState>();
    await settings.setPreset(_selected);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const Tier2NudgeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chibiState = context.watch<ChibiState>();
    final species = chibiState.chibi?.species;

    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              // Chibi with speech bubble
              if (species != null)
                ChibiSpriteWidget(
                  species: species,
                  animationName: _animationForPreset(),
                  width: 120,
                  height: 120,
                ),
              const SizedBox(height: 12),
              const Text(
                'How should I be?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              // Preset cards
              ...SensitivityPreset.values.map((preset) =>
                  _PresetCard(
                    preset: preset,
                    isSelected: _selected == preset,
                    onTap: () => setState(() => _selected = preset),
                  ),
              ),
              const Spacer(),
              // Confirm
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _confirm,
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
                    child: const Text("Let's go!"),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _animationForPreset() {
    switch (_selected) {
      case SensitivityPreset.relaxed:
        return 'sleeping'; // yawn/stretch mapped to slow idle
      case SensitivityPreset.focusFriendly:
        return 'idle';
      case SensitivityPreset.superFocused:
        return 'celebrating'; // punches air
    }
  }
}

class _PresetCard extends StatelessWidget {
  final SensitivityPreset preset;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetCard({
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final defaults = preset.defaults;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.amber : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              // Sensitivity indicator
              Column(
                children: List.generate(3, (i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Icon(
                      Icons.circle,
                      size: 8,
                      color: i < _intensityLevel()
                          ? Colors.amber
                          : Colors.white24,
                    ),
                  );
                }),
              ),
              const SizedBox(width: 16),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          preset.displayName,
                          style: TextStyle(
                            color: isSelected ? Colors.amber : Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (preset == SensitivityPreset.focusFriendly)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Default',
                              style: TextStyle(
                                  color: Colors.amber, fontSize: 11),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preset.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Annoyance: ${defaults['time_to_annoyance']}min  '
                      'Recovery: ${defaults['recovery_time']}min',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: Colors.amber, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  int _intensityLevel() {
    switch (preset) {
      case SensitivityPreset.relaxed:
        return 1;
      case SensitivityPreset.focusFriendly:
        return 2;
      case SensitivityPreset.superFocused:
        return 3;
    }
  }
}
