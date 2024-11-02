import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';

class LocationProvider with ChangeNotifier {
  loc.LocationData? _currentLocation;
  Function(LatLng)? onLocationUpdated;

  loc.LocationData? get currentLocation => _currentLocation;

  void updateLocation(loc.LocationData location) {
    _currentLocation = location;
    notifyListeners();
  }

  Future<void> initializeLocation() async {
    final location = loc.Location();

    if (await Permission.location.isGranted) {
      _currentLocation = await location.getLocation();
      notifyListeners();
      // Start listening for location updates
      location.onLocationChanged.listen((newLocation) {
        _currentLocation = newLocation;
        if (onLocationUpdated != null) {
          onLocationUpdated!(
              LatLng(newLocation.latitude!, newLocation.longitude!));
        }
        notifyListeners();
      }, onError: (error) {});
    }
  }
}
