import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:latlong2/latlong.dart';

part 'marker_model.g.dart';

@HiveType(typeId: 1) // Set a unique typeId for each model class
class MarkerModel {
  @HiveField(0)
  final double latitude;

  @HiveField(1)
  final double longitude;

  @HiveField(2)
  final double width;

  @HiveField(3)
  final double height;

  @HiveField(4)
  final Alignment? alignment;

  @HiveField(5)
  final bool? rotate;

  MarkerModel(
      {required this.latitude,
      required this.longitude,
      required this.width,
      required this.height,
      required this.alignment,
      required this.rotate});

  Marker toMarker() {
    return Marker(
        point: LatLng(latitude, longitude),
        width: width,
        height: height,
        alignment: alignment,
        rotate: rotate,
        child: Image.asset('Assets/Images/parking-location.png', scale: 18));
  }
}
