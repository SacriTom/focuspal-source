// Home screen: full-screen environment background, Chibi with
// mood-based animation, emoji speech bubbles, mood indicator,
// bottom navigation bar.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/chibi_state.dart';
import '../state/environment_state.dart';
import '../state/settings_state.dart';
import '../widgets/chibi_sprite.dart';
import '../widgets/environment_scene.dart';
import '../widgets/mood_indicator.dart';
import '../widgets/speech_bubble.dart';
import 'focus_timer_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize Chibi state on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chibiState = context.read<ChibiState>();
      if (!chibiState.hasChibi) {
        chibiState.loadChibi();
      }
      final envState = context.read<EnvironmentState>();
      envState.updateDayPhase();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final chibiState = context.read<ChibiState>();
    if (state == AppLifecycleState.resumed) {
      chibiState.onAppResumed();
      context.read<EnvironmentState>().updateDayPhase();
      // CP-011 follow-up: reconcile in-app Tier 2 toggle with the actual
      // Android Usage Access permission state on every resume.
      context.read<SettingsState>().reconcileTier2Permission();
    } else if (state == AppLifecycleState.paused) {
      chibiState.onAppPaused();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTab,
        children: const [
          _HomeTab(),
          FocusTimerScreen(),
          StatsScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isActive: _currentTab == 0,
                onTap: () => setState(() => _currentTab = 0),
              ),
              _NavItem(
                icon: Icons.explore_rounded,
                label: 'Focus',
                isActive: _currentTab == 1,
                onTap: () => setState(() => _currentTab = 1),
              ),
              _NavItem(
                icon: Icons.bar_chart_rounded,
                label: 'Stats',
                isActive: _currentTab == 2,
                onTap: () => setState(() => _currentTab = 2),
              ),
              _NavItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                isActive: _currentTab == 3,
                onTap: () => setState(() => _currentTab = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.amber : Colors.white54,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.amber : Colors.white54,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The actual home tab content with environment scene and Chibi.
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final chibiState = context.watch<ChibiState>();
    final species = chibiState.chibi?.species;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-screen environment background
        const EnvironmentScene(),

        // Mood indicator (top-right)
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          right: 16,
          child: MoodIndicator(
            mood: chibiState.mood,
            chibiName: chibiState.chibi?.name,
          ),
        ),

        // Home icon (top-left)
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.home, color: Colors.white70, size: 18),
                SizedBox(width: 4),
                Text(
                  'Home',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ),

        // Chibi + speech bubble (centre-bottom area)
        if (species != null)
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Speech bubble
                SpeechBubble(emoji: chibiState.speechEmoji),
                const SizedBox(height: 8),
                // Chibi - tappable
                GestureDetector(
                  onTap: () => chibiState.startInteraction(),
                  child: ChibiSpriteWidget(
                    species: species,
                    animationName: chibiState.currentAnimation,
                    width: 180,
                    height: 180,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
