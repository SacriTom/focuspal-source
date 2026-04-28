/// Stats screen: Focus history (sessions today/week), current streak,
/// mood timeline. Tier 2 locked features banner if not enabled.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/settings_state.dart';
import '../services/storage_service.dart';
import '../models/mood.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _todayMinutes = 0;
  int _streak = 0;
  List<MoodEntry> _moodHistory = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final minutes = await StorageService.getTodayFocusMinutes();
    final streak = await StorageService.getStreak();
    final moods = await StorageService.getMoodHistory(limit: 24);
    if (!mounted) return;
    setState(() {
      _todayMinutes = minutes;
      _streak = streak;
      _moodHistory = moods;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();

    return Container(
      color: const Color(0xFF1A237E),
      child: SafeArea(
        child: _loaded
            ? ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text(
                    'Your Journey',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Today's focus
                  _StatCard(
                    title: "Today's Focus",
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatValue(
                          label: 'Active',
                          value: _formatMinutes(_todayMinutes),
                          icon: Icons.timer,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white24,
                        ),
                        _StatValue(
                          label: 'Sessions',
                          value: '${(_todayMinutes / 25).ceil()}',
                          icon: Icons.explore,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Streak
                  _StatCard(
                    title: 'Current Streak',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.local_fire_department,
                            color: Colors.orange, size: 32),
                        const SizedBox(width: 8),
                        Text(
                          '$_streak ${_streak == 1 ? "day" : "days"}',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Mood timeline
                  _StatCard(
                    title: 'Recent Moods',
                    child: _moodHistory.isEmpty
                        ? Text(
                            'No mood data yet. Use the app to see your mood timeline.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 14,
                            ),
                          )
                        : Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _moodHistory
                                .take(12)
                                .map((entry) => Tooltip(
                                      message:
                                          '${entry.mood.label} - ${entry.reason ?? ""}',
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color:
                                              Colors.white.withValues(alpha: 0.08),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          entry.mood.emoji,
                                          style:
                                              const TextStyle(fontSize: 20),
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 16),
                  // Tier 2 promotion if not enabled
                  if (!settings.tier2Enabled)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline,
                              color: Colors.amber, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'See your full picture',
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Enable screen time access to unlock detailed stats.',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              )
            : const Center(
                child: CircularProgressIndicator(color: Colors.amber),
              ),
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m}m';
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _StatCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _StatValue extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatValue({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.amber, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
