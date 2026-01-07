import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CooldownButton extends StatefulWidget {
  final String title;
  final IconData? icon;
  final Duration cooldownDuration;
  final Duration initialRemaining;
  final Future<bool> Function() onPressed;

  /// onPressed must return:
  /// true  → start cooldown
  /// false → do nothing (error case)
  const CooldownButton({
    super.key,
    required this.title,
    required this.cooldownDuration,
    required this.initialRemaining,
    required this.onPressed,
    this.icon,
  });

  @override
  State<CooldownButton> createState() => _CooldownButtonState();
}

class _CooldownButtonState extends State<CooldownButton> {
  Timer? _timer;
  late Duration _remaining;
  bool _locked = false; // prevents double tap

  @override
  void initState() {
    super.initState();
    _remaining = widget.initialRemaining;

    if (_remaining.inSeconds > 0) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();

    setState(() {
      _remaining = widget.cooldownDuration;
      _locked = false;
    });

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      setState(() {
        _remaining -= const Duration(seconds: 1);
        if (_remaining.inSeconds <= 0) {
          _remaining = Duration.zero;
          _timer?.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isOnCooldown = _remaining.inSeconds > 0;
    final minutes = _remaining.inMinutes;
    final seconds = (_remaining.inSeconds % 60).toString().padLeft(2, '0');

    return ElevatedButton.icon(
      onPressed: (isOnCooldown || _locked)
          ? null
          : () async {
        setState(() => _locked = true); // immediate disable

        final success = await widget.onPressed();

        if (!mounted) return;

        if (success) {
          _startCooldown();
        } else {
          setState(() => _locked = false); // re-enable on failure
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isOnCooldown || _locked
            ? Colors.grey[500]
            : Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        textStyle: const TextStyle(fontSize: 18),
      ),
      icon: Icon(widget.icon),
      label: Text(
        isOnCooldown
            ? 'Please wait $minutes:$seconds'
            : widget.title,
        style: GoogleFonts.robotoSlab(),
      ),
    );
  }
}