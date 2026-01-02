import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';

part 'parkingspot_model.g.dart'; // This line links the generated file

@HiveType(typeId: 3) // This annotation triggers the generator
class ParkingSpotModel {
  @HiveField(0)
  final String address;

  @HiveField(1)
  final double latitude;

  @HiveField(2)
  final double longitude;

  @HiveField(3)
  final DateTime? timestamp;

  @HiveField(4)
  final double? probability;

  @HiveField(5)
  final int? reports;

  ParkingSpotModel({
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.probability,
    required this.reports,
  });

  Marker toMarker() {
    return Marker(
      point: LatLng(latitude, longitude),
      width: 80.0,
      height: 80.0,
      child: Image.asset('Assets/Images/parking-location.png', scale: 18),
    );
  }
}
