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
    required this.probability,
    required this.onTap,
  });


  Color getProbabilityColor() {
    if (probability! > 0.66) return Colors.green;
    if (probability! > 0.33) return Colors.orange;
    return Colors.red;
  }


  String getProbabilityLabel() {
    if (probability! > 0.66) return 'Υψηλή πιθανότητα';
    if (probability! > 0.33) return 'Μέτρια πιθανότητα';
    return 'Χαμηλή πιθανότητα';
  }


  String formatAge(Duration d) {
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