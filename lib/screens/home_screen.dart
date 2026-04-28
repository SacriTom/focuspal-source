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
/// A2 pass: rooms are visibly composed (wall + floor + furniture geometry)
/// in three side-by-side zones. Layout order on screen, left-to-right, is
/// kitchen | living room | bedroom (matches chibiAnchorFraction).
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
        return 0.83;
      case _HomeRoom.kitchen:
        return 0.17;
      case _HomeRoom.livingRoom:
        return 0.50;
    }
  }

  /// Wall colour when the room is the active zone. Soft warm tones.
  Color get wallActive {
    switch (this) {
      case _HomeRoom.bedroom:
        return const Color(0xFF3F4A78); // dusk blue
      case _HomeRoom.kitchen:
        return const Color(0xFF6B5840); // warm tan
      case _HomeRoom.livingRoom:
        return const Color(0xFF52456E); // muted plum
    }
  }

  /// Wall colour when not active  ~25% darker so the active zone reads.
  Color get wallDim {
    switch (this) {
      case _HomeRoom.bedroom:
        return const Color(0xFF2C355A);
      case _HomeRoom.kitchen:
        return const Color(0xFF4A3D2C);
      case _HomeRoom.livingRoom:
        return const Color(0xFF3A3151);
    }
  }

  Color get floorActive {
    switch (this) {
      case _HomeRoom.bedroom:
        return const Color(0xFF6B5A3E); // warm wood
      case _HomeRoom.kitchen:
        return const Color(0xFF847565); // tile
      case _HomeRoom.livingRoom:
        return const Color(0xFF5C4D3D); // dark wood
    }
  }

  Color get floorDim {
    switch (this) {
      case _HomeRoom.bedroom:
        return const Color(0xFF463C2A);
      case _HomeRoom.kitchen:
        return const Color(0xFF564D43);
      case _HomeRoom.livingRoom:
        return const Color(0xFF3D332A);
    }
  }
}

/// Three rooms rendered side by side with wall + floor + simple furniture
/// geometry. Visual style is intentionally graphic / non-pixel so it does
/// not fight the pixel-art Chibi sprite for visual attention.
class _RoomsScene extends StatelessWidget {
  final _HomeRoom activeRoom;
  const _RoomsScene({required this.activeRoom});

  @override
  Widget build(BuildContext context) {
    // Display order, left-to-right
    const order = [_HomeRoom.kitchen, _HomeRoom.livingRoom, _HomeRoom.bedroom];
    return Row(
      children: [
        for (int i = 0; i < order.length; i++)
          Expanded(
            child: _RoomColumn(
              room: order[i],
              isActive: order[i] == activeRoom,
              showRightDivider: i < order.length - 1,
            ),
          ),
      ],
    );
  }
}

class _RoomColumn extends StatelessWidget {
  final _HomeRoom room;
  final bool isActive;
  final bool showRightDivider;
  const _RoomColumn({
    required this.room,
    required this.isActive,
    required this.showRightDivider,
  });

  @override
  Widget build(BuildContext context) {
    final wall = isActive ? room.wallActive : room.wallDim;
    final floor = isActive ? room.floorActive : room.floorDim;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Wall + floor split
          Column(
            children: [
              Expanded(
                flex: 7,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  color: wall,
                ),
              ),
              Expanded(
                flex: 3,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  color: floor,
                ),
              ),
            ],
          ),
          // Skirting board line where wall meets floor
          FractionallySizedBox(
            alignment: Alignment.bottomCenter,
            heightFactor: 0.3,
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                height: 2,
                color: Colors.black.withValues(alpha: 0.25),
              ),
            ),
          ),
          // Furniture, anchored on the floor
          Align(
            alignment: const Alignment(0.0, 0.55),
            child: _RoomFurniture(room: room, isActive: isActive),
          ),
          // Right wall-divider line
          if (showRightDivider)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 2,
                color: Colors.black.withValues(alpha: 0.30),
              ),
            ),
        ],
      ),
    );
  }
}

class _RoomFurniture extends StatelessWidget {
  final _HomeRoom room;
  final bool isActive;
  const _RoomFurniture({required this.room, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final dim = isActive ? 1.0 : 0.55;
    switch (room) {
      case _HomeRoom.bedroom:
        return Opacity(opacity: dim, child: const _BedShape());
      case _HomeRoom.kitchen:
        return Opacity(opacity: dim, child: const _KitchenCounterShape());
      case _HomeRoom.livingRoom:
        return Opacity(opacity: dim, child: const _SofaShape());
    }
  }
}

class _BedShape extends StatelessWidget {
  const _BedShape();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 50,
      child: Stack(
        children: [
          // Mattress + frame
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFDDE3F0),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.black26),
              ),
            ),
          ),
          // Pillow
          Positioned(
            left: 6,
            top: 14,
            child: Container(
              width: 22,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.black26),
              ),
            ),
          ),
          // Headboard
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 6,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF8C5A3B),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KitchenCounterShape extends StatelessWidget {
  const _KitchenCounterShape();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 50,
      child: Stack(
        children: [
          // Counter
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 26,
              decoration: BoxDecoration(
                color: const Color(0xFFD8B886),
                border: Border.all(color: Colors.black38),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(2)),
              ),
            ),
          ),
          // Pot
          Positioned(
            left: 32,
            bottom: 22,
            child: Container(
              width: 24,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFF455A64),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.black54),
              ),
            ),
          ),
          // Steam dot
          Positioned(
            left: 42,
            bottom: 40,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SofaShape extends StatelessWidget {
  const _SofaShape();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 50,
      child: Stack(
        children: [
          // Seat
          Positioned(
            left: 6,
            right: 6,
            bottom: 0,
            child: Container(
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFF6FA5C9),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.black26),
              ),
            ),
          ),
          // Backrest
          Positioned(
            left: 6,
            right: 6,
            top: 4,
            child: Container(
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF89C3E5),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8)),
                border: Border.all(color: Colors.black26),
              ),
            ),
          ),
          // Left arm
          Positioned(
            left: 0,
            top: 6,
            child: Container(
              width: 8,
              height: 26,
              decoration: BoxDecoration(
                color: const Color(0xFF5A8FB0),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.black26),
              ),
            ),
          ),
          // Right arm
          Positioned(
            right: 0,
            top: 6,
            child: Container(
              width: 8,
              height: 26,
              decoration: BoxDecoration(
                color: const Color(0xFF5A8FB0),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.black26),
              ),
            ),
          ),
        ],
      ),
    );
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
        // A2: three-room composed scene with wall + floor + furniture
        // geometry. Replaces the simple gradient from A1.
        _RoomsScene(activeRoom: room),

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
