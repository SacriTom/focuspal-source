// Home screen: single living-room scene composed of cropped Interior.png
// sprites (bookcase, coffee table, round rug) on a warm wall + wood floor.
// Larger Chibi (~35% screen height) gives the camera a "closer" feel that
// the previous multi-room iterations were missing. Bottom-nav unchanged.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/chibi_state.dart';
import '../state/environment_state.dart';
import '../state/settings_state.dart';
import '../widgets/chibi_sprite.dart';
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

/// The Home tab: one composed living-room scene.
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final chibiState = context.watch<ChibiState>();
    final species = chibiState.chibi?.species;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Composed living-room background (wall + floor + furniture sprites).
        const _LivingRoomScene(),

        // Mood indicator (top-right).
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          right: 16,
          child: MoodIndicator(
            mood: chibiState.mood,
            chibiName: chibiState.chibi?.name,
          ),
        ),

        // Room badge (top-left). One room, one label.
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('\u{1F6CB}️', style: TextStyle(fontSize: 14)),
                SizedBox(width: 6),
                Text(
                  'Living Room',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Chibi + speech bubble. Anchored centre-bottom; sized larger than
        // the previous iterations so the camera reads as "close" — which
        // the user feedback explicitly asked for.
        if (species != null)
          Positioned(
            bottom: 90,
            left: 0,
            right: 0,
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
                    // ~1.6× the previous size — practical maximum that
                    // fits typical phone widths (~411dp) without clipping.
                    width: 380,
                    height: 380,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Single isometric pixel-art house image used as the backdrop. Fills the
/// screen via BoxFit.cover so the Chibi appears to live inside the room.
class _LivingRoomScene extends StatelessWidget {
  const _LivingRoomScene();

  static const _backdrop = 'assets/environments/home/room_backdrop.jpg';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black, // matches the dark frame around the house art
      child: Image.asset(
        _backdrop,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.none, // keep crisp pixel edges
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }
}
