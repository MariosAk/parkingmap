import 'package:flutter_map/flutter_map.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:latlong2/latlong.dart';

part 'latlng_bounds_model.g.dart';

@HiveType(typeId: 2)
class LatLngBoundsModel {
  @HiveField(0)
  final double swLat;
  @HiveField(1)
  final double swLng;
  @HiveField(2)
  final double neLat;
  @HiveField(3)
  final double neLng;

  LatLngBoundsModel({
    required this.swLat,
    required this.swLng,
    required this.neLat,
    required this.neLng,
  });

  // Helper method to convert back to LatLngBounds if needed
  LatLngBounds toLatLngBounds() {
    return LatLngBounds(
      LatLng(swLat, swLng),
      LatLng(neLat, neLng),
    );
  }
}
