// Home screen: full-screen environment background, Chibi with
// mood-based animation, emoji speech bubbles, mood indicator,
// bottom navigation bar.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mood.dart';
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

/// Distinct rooms surfaced on the Home tab.
/// A1 pass: name + emoji at top, Chibi position shifts horizontally so the
/// space reads as bedroom / kitchen / living room rather than one cluttered
/// scene. Future passes (A2, A3) will replace the label with real wall art.
enum _HomeRoom {
  bedroom,
  kitchen,
  livingRoom;

  String get label {
    switch (this) {
      case _HomeRoom.bedroom:
        return 'Bedroom';
      case _HomeRoom.kitchen:
        return 'Kitchen';
      case _HomeRoom.livingRoom:
        return 'Living Room';
    }
  }

  /// 1-glyph emoji that prints alongside the room label.
  String get emoji {
    switch (this) {
      case _HomeRoom.bedroom:
        return '\u{1F6CF}️'; // 🛏
      case _HomeRoom.kitchen:
        return '\u{1F373}'; // 🍳
      case _HomeRoom.livingRoom:
        return '\u{1F6CB}️'; // 🛋
    }
  }

  /// Horizontal anchor for the Chibi as a fraction of screen width.
  /// 0.5 = centre. Bedroom leans right (sleep area), kitchen leans left,
  /// living room is centre.
  double get chibiAnchorFraction {
    switch (this) {
      case _HomeRoom.bedroom:
        return 0.72;
      case _HomeRoom.kitchen:
        return 0.28;
      case _HomeRoom.livingRoom:
        return 0.50;
    }
  }
}

_HomeRoom _roomFor(ChibiState s) {
  if (s.mood == MoodState.sleepy) return _HomeRoom.bedroom;
  // Cooking emoji 🍳 -> Kitchen.
  if (s.speechEmoji == '\u{1F373}') return _HomeRoom.kitchen;
  return _HomeRoom.livingRoom;
}

/// The actual home tab content with environment scene and Chibi.
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final chibiState = context.watch<ChibiState>();
    final species = chibiState.chibi?.species;
    final room = _roomFor(chibiState);
    final screenW = MediaQuery.of(context).size.width;

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

        // Room badge (top-left). Replaces the static 'Home' chip and gives
        // the user the spatial cue of which room their Chibi is in.
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: Container(
              key: ValueKey(room),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    room.emoji,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    room.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Chibi + speech bubble. Position glides horizontally to the room
        // anchor so the Chibi appears to walk between rooms.
        if (species != null)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            bottom: 80,
            left: (screenW * room.chibiAnchorFraction) - 90,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SpeechBubble(emoji: chibiState.speechEmoji),
                const SizedBox(height: 8),
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
