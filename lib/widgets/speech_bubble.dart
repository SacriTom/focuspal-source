/// Floating emoji speech bubble that appears above the Chibi.
/// Fades in, holds, fades out. Driven by ChibiState.speechEmoji.

import 'package:flutter/material.dart';

class SpeechBubble extends StatefulWidget {
  final String? emoji;
  final double fontSize;

  const SpeechBubble({
    super.key,
    this.emoji,
    this.fontSize = 32,
  });

  @override
  State<SpeechBubble> createState() => _SpeechBubbleState();
}

class _SpeechBubbleState extends State<SpeechBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _floatAnimation;
  String? _displayedEmoji;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _floatAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    if (widget.emoji != null) {
      _displayedEmoji = widget.emoji;
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(SpeechBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.emoji != oldWidget.emoji) {
      if (widget.emoji != null) {
        _displayedEmoji = widget.emoji;
        _controller.forward(from: 0);
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_displayedEmoji == null) return const SizedBox.shrink();

    return SlideTransition(
      position: _floatAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            _displayedEmoji!,
            style: TextStyle(fontSize: widget.fontSize),
          ),
        ),
      ),
    );
  }
}
