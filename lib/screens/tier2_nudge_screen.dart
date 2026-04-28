/// Tier 2 permission nudge screen.
/// Chibi delivers permission request. Explains what, how, and why.
/// "Enable" opens UsageStats settings. "Skip for now" proceeds to home.
/// Non-punishing (D-031).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/chibi_state.dart';
import '../state/settings_state.dart';
import '../services/storage_service.dart';
import '../widgets/chibi_sprite.dart';
import 'home_screen.dart';

class Tier2NudgeScreen extends StatelessWidget {
  const Tier2NudgeScreen({super.key});

  static const _usageStatsChannel = MethodChannel('com.focuspal/usage_stats');

  Future<void> _enableTier2(BuildContext context) async {
    // Try to open system usage access settings
    try {
      await _usageStatsChannel.invokeMethod('openUsageAccessSettings');
    } catch (e) {
      // Platform channel not available in Phase 1 prototype.
      // Show a simulated success for demo purposes.
      debugPrint('Usage stats channel not available: $e');
    }

    // For Phase 1, simulate enabling
    if (context.mounted) {
      final settings = context.read<SettingsState>();
      await settings.setTier2Enabled(true);
      _proceed(context);
    }
  }

  void _skip(BuildContext context) {
    _proceed(context);
  }

  Future<void> _proceed(BuildContext context) async {
    await StorageService.setOnboardingComplete(true);
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chibiState = context.watch<ChibiState>();
    final species = chibiState.chibi?.species;
    final name = chibiState.chibi?.name ?? 'Your Chibi';

    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 48),
              // Chibi with magnifying glass speech bubble
              if (species != null)
                ChibiSpriteWidget(
                  species: species,
                  animationName: 'idle',
                  width: 140,
                  height: 140,
                ),
              const SizedBox(height: 8),
              // Magnifying glass + phone + question mark
              const Text(
                '\u{1F50D}\u{1F4F1}\u{2753}',
                style: TextStyle(fontSize: 28),
              ),
              const SizedBox(height: 24),
              // Explanation card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Right now I can only see when you open this app.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'If you let me see your screen time, I can respond to '
                      "your real habits -- and you'll unlock evolution, skills, "
                      'and progress tracking.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          color: Colors.white.withValues(alpha: 0.6),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your data stays on this phone. '
                            "$name doesn't send it anywhere.",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Enable button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _enableTier2(context),
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
                  child: const Text('Enable Screen Time Access'),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '(takes you to Settings)',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              // Skip
              TextButton(
                onPressed: () => _skip(context),
                child: Text(
                  'Skip for now',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
