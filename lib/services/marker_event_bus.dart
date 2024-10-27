import 'dart:async';
import 'package:latlong2/latlong.dart';

// Define a global event bus
class MarkerEventBus {
  static final MarkerEventBus _instance = MarkerEventBus._internal();
  factory MarkerEventBus() => _instance;

  MarkerEventBus._internal();

  final StreamController<LatLng> _streamController =
      StreamController.broadcast();

  Stream<LatLng> get markerStream => _streamController.stream;

  void addMarker(LatLng markerPosition) {
    _streamController.add(markerPosition);
  }

  void dispose() {
    _streamController.close();
  }
}
