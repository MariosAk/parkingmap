import 'package:flutter/material.dart';

class ParkingSpotTile extends StatelessWidget {
  final double distanceMeters;
  final Duration age;
  final double? probability; // 0.0 – 1.0
  final VoidCallback onTap;


  const ParkingSpotTile({
    super.key,
    required this.distanceMeters,
    required this.age,
    this.probability,
    required this.onTap,
  });

  double get _calculatedProbability {
    final minutes = age.inMinutes;

    // Spot is expired after 30 minutes
    if (minutes >= 30) return 0.0;

    // Very fresh (0-5 mins)
    if (minutes <= 5) return 1.0;

    // Decay over the remaining 25 minutes
    // at 10 mins -> 0.8
    // at 17.5 mins -> 0.5
    // at 25 mins -> 0.2
    double remainingRatio = (30 - minutes) / 25.0;
    return remainingRatio.clamp(0.0, 1.0);
  }

  Color getProbabilityColor() {
    final prob = _calculatedProbability;
    if (prob > 0.66) return Colors.green;
    if (prob > 0.33) return Colors.orange;
    return Colors.red;
  }


  String getProbabilityLabel() {
    final prob = _calculatedProbability;

    if (age.inMinutes >= 30) return 'Έληξε';

    if (prob > 0.66) return 'Υψηλή πιθανότητα';
    if (prob > 0.33) return 'Μέτρια πιθανότητα';
    return 'Χαμηλή πιθανότητα';
  }


  String formatAge(Duration d) {
    if (d.inMinutes >= 30) return 'έληξε';
    if (d.inMinutes < 1) return 'μόλις τώρα';
    if (d.inMinutes < 60) return 'πριν ${d.inMinutes} λεπτά';
    return 'πριν ${d.inHours} ώρες';
  }


  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.local_parking),
      title: Text('${distanceMeters.toStringAsFixed(0)} m',
          style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(formatAge(age)),
          Text(
            getProbabilityLabel(),
            style: TextStyle(color: getProbabilityColor()),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}