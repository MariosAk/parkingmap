import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/globals.dart' as globals;

class ParkingSpotTile extends StatelessWidget {
  final double distanceMeters;
  final Duration age;
  final double? probability; // 0.0 – 1.0
  final VoidCallback onTap;
  final int reportCount;
  final int activeSearchers;

  const ParkingSpotTile({
    super.key,
    required this.distanceMeters,
    required this.age,
    this.probability,
    required this.onTap,
    required this.reportCount,
    required this.activeSearchers,
  });

  // double get _calculatedProbability {
  //   final minutes = age.inMinutes;
  //
  //   // Spot is expired after 15 minutes
  //   if (minutes >= 15) return 0.0;
  //
  //   // Very fresh (0-5 mins)
  //   if (minutes <= 5) return 1.0;
  //
  //   // Decay over the remaining 10 minutes
  //   double remainingRatio = (15 - minutes) / 10.0;
  //   return remainingRatio.clamp(0.0, 1.0);
  // }

  String formatAge(Duration d) {
    if (d.inMinutes >= 15) return 'Έληξε';
    if (d.inMinutes < 1) return 'Μόλις τώρα';
    if (d.inMinutes < 60) return 'Πριν ${d.inMinutes} λεπτά';
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
            globals.getProbabilityLabel(probability, age, activeSearchers),
            style: TextStyle(color: globals.getProbabilityColor(probability, age, activeSearchers)),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.flag_circle, // An icon representing reports
            color: reportCount >= 3 ? Colors.red : Colors.black54,
            size: 20,
          ),
          const SizedBox(height: 2),
          Text(
            reportCount.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
              fontSize: 14,
            ),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}