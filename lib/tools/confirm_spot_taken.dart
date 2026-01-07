import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MarkAsTakenCooldownDialog extends StatefulWidget {
  final Duration cooldownRemaining;
  final VoidCallback onConfirm;

  const MarkAsTakenCooldownDialog({
    super.key,
    required this.cooldownRemaining,
    required this.onConfirm,
  });

  @override
  State<MarkAsTakenCooldownDialog> createState() =>
      _MarkAsTakenCooldownDialogState();
}

class _MarkAsTakenCooldownDialogState
    extends State<MarkAsTakenCooldownDialog>
    with SingleTickerProviderStateMixin {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.cooldownRemaining;

    if (_remaining.inSeconds > 0) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final bool canConfirm = _remaining == Duration.zero;
    final double progress = canConfirm
        ? 1
        : 1 -
        (_remaining.inSeconds /
            widget.cooldownRemaining.inSeconds);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 12,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                canConfirm
                  ? Icons.beenhere_rounded
                  : Icons.lock_clock_rounded,
                size: 40,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              "Spot Taken?",
              style: GoogleFonts.robotoSlab(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              canConfirm
                  ? "You can now confirm that this spot is taken."
                  : "To prevent abuse, you can confirm again once the cooldown expires.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // Countdown + Progress
            if (!canConfirm) ...[
              LinearProgressIndicator(
                value: progress.clamp(0, 1),
                minHeight: 6,
                borderRadius: BorderRadius.circular(6),
                backgroundColor: Colors.grey[200],
                valueColor:
                AlwaysStoppedAnimation<Color>(Colors.blue.shade800),
              ),
              const SizedBox(height: 8),
              Text(
                "Available in ${_formatDuration(_remaining)}",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.blue[900],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      "Cancel",
                      style: GoogleFonts.robotoSlab(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: ElevatedButton(
                      key: ValueKey(canConfirm),
                      onPressed: canConfirm
                          ? () {
                        widget.onConfirm();
                        Navigator.of(context).pop();
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[900],
                        disabledBackgroundColor: Colors.grey[300],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        canConfirm
                            ? "Confirm"
                            : "Confirm (${_formatDuration(_remaining)})",
                        style: GoogleFonts.robotoSlab(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
