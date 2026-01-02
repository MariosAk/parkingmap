import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CooldownButton extends StatefulWidget {
  final String title;
  final Duration cooldownDuration;
  final String cooldownKey; // Key to store the timestamp in SharedPreferences
  final Future<void> Function() onPressed;

  const CooldownButton({
    super.key,
    required this.title,
    required this.cooldownDuration,
    required this.cooldownKey,
    required this.onPressed,
  });

  @override
  State<CooldownButton> createState() => _CooldownButtonState();
}

class _CooldownButtonState extends State<CooldownButton> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _checkCooldown();
    // Set up a periodic timer to update the UI every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _checkCooldown());
  }

  @override
  void dispose() {
    _timer?.cancel(); // Always cancel the timer to prevent memory leaks
    super.dispose();
  }

  Future<void> _checkCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActionTimeStr = prefs.getString(widget.cooldownKey);

    if (lastActionTimeStr != null) {
      final lastActionTime = DateTime.parse(lastActionTimeStr);
      final difference = DateTime.now().difference(lastActionTime);

      if (difference < widget.cooldownDuration) {
        if (mounted) {
          setState(() {
            _remainingTime = widget.cooldownDuration - difference;
          });
        }
      } else {
        if (mounted && _remainingTime != Duration.zero) {
          setState(() {
            _remainingTime = Duration.zero;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isOnCooldown = _remainingTime.inSeconds > 0;

    return ElevatedButton(
      onPressed: isOnCooldown ? null : widget.onPressed, // Disable button if on cooldown
      style: ElevatedButton.styleFrom(
        backgroundColor: isOnCooldown ? Colors.grey[700] : Colors.blue[900], // Visual feedback
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        // This makes the button's disabled state look better
        disabledBackgroundColor: Colors.grey[400],
        disabledForegroundColor: Colors.grey[700],
      ),
      child: Text(
        // Show the title or the remaining time
        isOnCooldown
            ? 'Wait ${_remainingTime.inSeconds}s'
            : widget.title,
        style: GoogleFonts.robotoSlab(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
