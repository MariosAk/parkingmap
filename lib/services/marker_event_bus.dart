import 'dart:async';
import 'package:latlong2/latlong.dart';

enum MarkerEventType { add, delete }

class MarkerEvent {
  final MarkerEventType type;
  final LatLng position;

  MarkerEvent({required this.type, required this.position});
}

// Define a global event bus
class MarkerEventBus {
  static final MarkerEventBus _instance = MarkerEventBus._internal();
  factory MarkerEventBus() => _instance;

  MarkerEventBus._internal();

  final StreamController<MarkerEvent> _streamController =
      StreamController.broadcast();

  Stream<MarkerEvent> get markerStream => _streamController.stream;

  void addMarker(LatLng markerPosition) {
    _streamController
        .add(MarkerEvent(type: MarkerEventType.add, position: markerPosition));
  }

  void deleteMarker(LatLng markerPosition) {
    _streamController.add(
        MarkerEvent(type: MarkerEventType.delete, position: markerPosition));
  }

  void dispose() {
    _streamController.close();
  }
}
