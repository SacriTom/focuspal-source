// Focus timer screen: passive mode info + active mode.
// Duration selector (25/45/60/90 min pills), start button,
// adventure scene during active session, countdown timer,
// peek mechanic (D-024: no penalty for checking).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/chibi_state.dart';
import '../state/focus_state.dart';
import '../models/mood.dart';
import '../widgets/chibi_sprite.dart';
import '../widgets/environment_scene.dart';

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> {
  int _selectedDuration = 25;
  static const _durations = [25, 45, 60, 90];

  @override
  Widget build(BuildContext context) {
    final focusState = context.watch<FocusState>();

    if (focusState.hasActiveSession) {
      if (focusState.remainingSeconds <= 0 &&
          focusState.activeSession!.completed) {
        return _buildCompletionView(context, focusState);
      }
      return _buildActiveSessionView(context, focusState);
    }
    return _buildPreSessionView(context, focusState);
  }

  Widget _buildPreSessionView(BuildContext context, FocusState focusState) {
    final chibiState = context.watch<ChibiState>();
    final species = chibiState.chibi?.species;

    return Container(
      color: const Color(0xFF1A237E),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              const Text(
                'Start an adventure!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Put your phone down and let ${chibiState.chibi?.name ?? "your Chibi"} explore',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Passive-baseline info strip (smoke test note 8).
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Passive mode is always on — '
                        '${chibiState.chibi?.name ?? "your Chibi"} '
                        'reads your in-app focus signal even without a session.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Chibi with adventure gear (pre-session). Sized larger to
              // match the home-screen camera distance — was 160; the
              // 200 here keeps room for the duration pills + START
              // button below.
              if (species != null)
                ChibiSpriteWidget(
                  species: species,
                  animationName: 'walking',
                  width: 200,
                  height: 200,
                ),
              const SizedBox(height: 8),
              const Text(
                '\u{1F9ED}\u{2728}',
                style: TextStyle(fontSize: 28),
              ),
              const Spacer(),
              // Duration pills
              const Text(
                'Duration',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _durations.map((d) {
                  final isSelected = d == _selectedDuration;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedDuration = d),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.amber
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected
                                ? Colors.amber
                                : Colors.white24,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          '${d}m',
                          style: TextStyle(
                            color: isSelected ? Colors.black87 : Colors.white70,
                            fontSize: 16,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              // Start button
              SizedBox(
                width: 200,
                height: 200,
                child: GestureDetector(
                  onTap: () => _startSession(context),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.amber, width: 4),
                      color: Colors.amber.withValues(alpha: 0.15),
                    ),
                    child: const Center(
                      child: Text(
                        'START',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSessionView(BuildContext context, FocusState focusState) {
    final chibiState = context.watch<ChibiState>();
    final species = chibiState.chibi?.species;
    final progress = focusState.progress;

    // Progress ring colour: warm amber/gold spectrum throughout the
    // session (matches FocusPal brand palette). Starts as a softer
    // amber, deepens toward gold as completion approaches.
    final progressColor = Color.lerp(
      const Color(0xFFFFD180), // soft amber
      const Color(0xFFFFB300), // gold
      progress,
    )!;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Adventure background
        const EnvironmentScene(isAdventure: true),

        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Active-session banner: lighter weight + a warm amber drop
              // shadow over the existing readability shadow, so the line
              // reads as celebratory rather than dialog-style bold.
              Text(
                '${chibiState.chibi?.name ?? "Chibi"} is exploring!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  shadows: [
                    Shadow(
                      color: Color(0xCC000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                    Shadow(
                      color: Color(0x66FFB300),
                      blurRadius: 14,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Walking Chibi  same camera distance as home so the
              // active session feels continuous with the home scene.
              // 320 is the practical max with a 180 progress ring and
              // pause/end buttons sharing the screen below.
              if (species != null)
                ChibiSpriteWidget(
                  species: species,
                  animationName: 'adventuring',
                  width: 320,
                  height: 320,
                ),
              const SizedBox(height: 24),
              // Progress ring with timer
              SizedBox(
                width: 180,
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(progressColor),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          focusState.remainingFormatted,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 4),
                            ],
                          ),
                        ),
                        Text(
                          'remaining',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Pause / Abandon buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!focusState.isPaused)
                    _ActionButton(
                      label: 'Pause',
                      icon: Icons.pause,
                      onTap: () => focusState.pauseSession(),
                    )
                  else
                    _ActionButton(
                      label: 'Resume',
                      icon: Icons.play_arrow,
                      onTap: () => focusState.resumeSession(),
                    ),
                  const SizedBox(width: 24),
                  _ActionButton(
                    label: 'End',
                    icon: Icons.stop,
                    onTap: () => _confirmAbandon(context, focusState),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionView(BuildContext context, FocusState focusState) {
    final chibiState = context.watch<ChibiState>();
    final species = chibiState.chibi?.species;

    return Container(
      color: const Color(0xFF1A237E),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 48),
              const Text(
                'Adventure complete!',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (species != null)
                ChibiSpriteWidget(
                  species: species,
                  animationName: 'celebrating',
                  width: 320,
                  height: 320,
                ),
              const SizedBox(height: 16),
              // Treasure reward placeholder
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      '\u{1F381}',
                      style: TextStyle(fontSize: 48),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Adventure Reward',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cosmetics coming in Phase 2!',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // Set mood to ecstatic on completion
                    chibiState.setMood(
                      MoodState.ecstatic,
                      reason: 'Completed adventure',
                    );
                    focusState.clearCompletedSession();
                  },
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
                  child: const Text('Back to Home'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _startSession(BuildContext context) {
    final focusState = context.read<FocusState>();
    focusState.startSession(_selectedDuration);
  }

  void _confirmAbandon(BuildContext context, FocusState focusState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF283593),
        title: const Text(
          'End adventure?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'No penalty for ending early (D-024). '
          'Your Chibi understands!',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep going',
                style: TextStyle(color: Colors.amber)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              focusState.abandonSession();
            },
            child: Text('End here',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
