// Settings screen: Preset switcher, individual sensitivity sliders,
// sleep time picker, Tier 2 toggle, about section.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/settings_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _usageStatsChannel = MethodChannel('com.focuspal/usage_stats');

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();

    return Container(
      color: const Color(0xFF1A237E),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Sensitivity Preset
            _SectionTitle(title: 'Sensitivity Preset'),
            const SizedBox(height: 8),
            _PresetSelector(
              selected: settings.preset,
              onSelect: (preset) => settings.setPreset(preset),
            ),
            const SizedBox(height: 8),
            // Friendly Chibi-voice description of the active preset.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Padding(
                key: ValueKey(settings.preset),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.format_quote,
                      size: 14,
                      color: Colors.amber.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        settings.preset.description,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Fine-tune (expandable)
            _FineTuneSection(settings: settings),
            const SizedBox(height: 24),

            // Sleep Schedule
            _SectionTitle(title: 'Sleep Schedule'),
            const SizedBox(height: 8),
            _SleepScheduleRow(
              label: 'Bedtime',
              hour: settings.bedtimeHour,
              minute: settings.bedtimeMinute,
              onChanged: (h, m) => settings.setBedtime(h, m),
            ),
            const SizedBox(height: 8),
            _SleepScheduleRow(
              label: 'Wake time',
              hour: settings.wakeHour,
              minute: settings.wakeMinute,
              onChanged: (h, m) => settings.setWakeTime(h, m),
            ),
            const SizedBox(height: 24),

            // Tier 2 toggle
            _SectionTitle(title: 'Screen Time Access'),
            const SizedBox(height: 8),
            _Tier2Toggle(
              enabled: settings.tier2Enabled,
              onToggle: (v) async {
                if (v) {
                  try {
                    await _usageStatsChannel
                        .invokeMethod('openUsageAccessSettings');
                  } catch (e) {
                    debugPrint('Platform channel not available: $e');
                  }
                }
                settings.setTier2Enabled(v);
              },
            ),
            const SizedBox(height: 24),

            // About
            _SectionTitle(title: 'About'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FocusPal v1.0.0',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'A Tamagotchi-style screen-time companion.\n'
                    'Your Chibi thrives when you put the phone down.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.amber,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _PresetSelector extends StatelessWidget {
  final SensitivityPreset selected;
  final ValueChanged<SensitivityPreset> onSelect;

  const _PresetSelector({
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: SensitivityPreset.values.map((preset) {
          final isSelected = preset == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(preset),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.amber.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: Colors.amber, width: 1.5)
                      : null,
                ),
                child: Text(
                  _shortName(preset),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.amber : Colors.white70,
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _shortName(SensitivityPreset preset) {
    switch (preset) {
      case SensitivityPreset.relaxed:
        return 'Relaxed';
      case SensitivityPreset.focusFriendly:
        return 'Focus';
      case SensitivityPreset.superFocused:
        return 'Super';
    }
  }
}

class _FineTuneSection extends StatefulWidget {
  final SettingsState settings;

  const _FineTuneSection({required this.settings});

  @override
  State<_FineTuneSection> createState() => _FineTuneSectionState();
}

class _FineTuneSectionState extends State<_FineTuneSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              _SectionTitle(title: 'Fine-Tune'),
              const SizedBox(width: 8),
              Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.amber,
                size: 20,
              ),
            ],
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 12),
          _SliderRow(
            label: 'Time to annoyance',
            value: s.timeToAnnoyance,
            unit: 'min',
            min: s.preset == SensitivityPreset.relaxed
                ? SettingsState.relaxedMinimums['time_to_annoyance']!
                : 5,
            max: 120,
            onChanged: (v) => s.setTimeToAnnoyanceValue(v),
          ),
          _SliderRow(
            label: 'Recovery time',
            value: s.recoveryTime,
            unit: 'min',
            min: s.preset == SensitivityPreset.relaxed
                ? SettingsState.relaxedMinimums['recovery_time']!
                : 1,
            max: 30,
            onChanged: (v) => s.setRecoveryTimeValue(v),
          ),
          _SliderRow(
            label: 'Ecstatic threshold',
            value: s.ecstaticThreshold,
            unit: 'min',
            min: s.preset == SensitivityPreset.relaxed
                ? SettingsState.relaxedMinimums['ecstatic_threshold']!
                : 10,
            max: 180,
            onChanged: (v) => s.setEcstaticThresholdValue(v),
          ),
          _SliderRow(
            label: 'Annoyance escalation',
            value: s.annoyanceEscalation,
            unit: 'min',
            min: s.preset == SensitivityPreset.relaxed
                ? SettingsState.relaxedMinimums['annoyance_escalation']!
                : 3,
            max: 60,
            onChanged: (v) => s.setAnnoyanceEscalationValue(v),
          ),
        ],
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final int value;
  final String unit;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
          ),
          // Minus button
          _StepButton(
            icon: Icons.remove,
            onTap: value > min ? () => onChanged(value - 1) : null,
          ),
          // Value
          SizedBox(
            width: 64,
            child: Text(
              '$value $unit',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Plus button
          _StepButton(
            icon: Icons.add,
            onTap: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: onTap != null
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.03),
        ),
        child: Icon(
          icon,
          color: onTap != null ? Colors.white70 : Colors.white24,
          size: 18,
        ),
      ),
    );
  }
}

class _SleepScheduleRow extends StatelessWidget {
  final String label;
  final int hour;
  final int minute;
  final void Function(int hour, int minute) onChanged;

  const _SleepScheduleRow({
    required this.label,
    required this.hour,
    required this.minute,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: hour, minute: minute),
          builder: (context, child) {
            return Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: Colors.amber,
                  surface: Color(0xFF283593),
                ),
              ),
              child: child!,
            );
          },
        );
        if (time != null) {
          onChanged(time.hour, time.minute);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Text(
              timeStr,
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.access_time, color: Colors.white54, size: 18),
          ],
        ),
      ),
    );
  }
}

class _Tier2Toggle extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onToggle;

  const _Tier2Toggle({
    required this.enabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  enabled ? 'Active' : 'Disabled',
                  style: TextStyle(
                    color: enabled ? Colors.green : Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Switch(
                value: enabled,
                onChanged: onToggle,
                activeThumbColor: Colors.amber,
              ),
            ],
          ),
          if (!enabled) ...[
            const SizedBox(height: 8),
            Text(
              'Enable screen time access to unlock your Chibi\'s full potential.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
          ],
          if (enabled) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.check_circle,
                    color: Colors.green.withValues(alpha: 0.7), size: 16),
                const SizedBox(width: 6),
                Text(
                  'Screen time tracking enabled',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
