// Top-right mood emoji indicator with background glow.
// Shows current mood state with tappable tooltip.

import 'package:flutter/material.dart';
import '../models/mood.dart';

class MoodIndicator extends StatelessWidget {
  final MoodState mood;
  final String? chibiName;
  final VoidCallback? onTap;

  const MoodIndicator({
    super.key,
    required this.mood,
    this.chibiName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => _showMoodTooltip(context),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.3),
          boxShadow: [
            BoxShadow(
              color: _moodGlowColor().withValues(alpha: 0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            mood.emoji,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }

  Color _moodGlowColor() {
    switch (mood) {
      case MoodState.ecstatic:
        return Colors.amber;
      case MoodState.happy:
        return Colors.green;
      case MoodState.content:
        return Colors.lightBlue;
      case MoodState.annoyed:
        return Colors.orange;
      case MoodState.sad:
        return Colors.blueGrey;
      case MoodState.sleepy:
        return Colors.indigo;
    }
  }

  String _moodDescription() {
    final name = chibiName ?? 'Your Chibi';
    switch (mood) {
      case MoodState.ecstatic:
        return '$name is over the moon!';
      case MoodState.happy:
        return '$name is enjoying the quiet.';
      case MoodState.content:
        return '$name is feeling okay.';
      case MoodState.annoyed:
        return '$name wants some space.';
      case MoodState.sad:
        return '$name misses the quiet.';
      case MoodState.sleepy:
        return '$name is sleeping soundly.';
    }
  }

  void _showMoodTooltip(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${mood.label}: ${_moodDescription()}'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black87,
      ),
    );
  }
}
