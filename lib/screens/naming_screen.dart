/// Naming screen: Chibi displayed with curious Idle animation.
/// Text input "What would you like to call me?"
/// On submit, Chibi does Jump celebration.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chibi.dart';
import '../state/chibi_state.dart';
import '../widgets/chibi_sprite.dart';
import 'preset_screen.dart';

class NamingScreen extends StatefulWidget {
  final ChibiSpecies species;

  const NamingScreen({super.key, required this.species});

  @override
  State<NamingScreen> createState() => _NamingScreenState();
}

class _NamingScreenState extends State<NamingScreen> {
  final _nameController = TextEditingController();
  bool _celebrating = false;
  String _currentAnimation = 'idle';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    // Create Chibi in state
    final chibiState = context.read<ChibiState>();
    await chibiState.createChibi(widget.species, name);

    setState(() {
      _celebrating = true;
      _currentAnimation = 'celebrating';
    });

    // Wait for celebration, then navigate
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const PresetScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Chibi sprite
              ChibiSpriteWidget(
                species: widget.species,
                animationName: _currentAnimation,
                width: 180,
                height: 180,
              ),
              const SizedBox(height: 24),
              // Celebration or naming prompt
              if (_celebrating) ...[
                Text(
                  _nameController.text.trim(),
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '\u{2764}\uFE0F',
                  style: TextStyle(fontSize: 32),
                ),
              ] else ...[
                const Text(
                  'What would you like to call me?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Name input
                TextField(
                  controller: _nameController,
                  maxLength: 12,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    counterStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.amber, width: 2),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _submitName(),
                ),
              ],
              const Spacer(),
              // Confirm button
              if (!_celebrating)
                Padding(
                  padding: const EdgeInsets.only(bottom: 48),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _nameController.text.trim().isNotEmpty
                          ? _submitName
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black87,
                        disabledBackgroundColor:
                            Colors.amber.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text("That's my name!"),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
