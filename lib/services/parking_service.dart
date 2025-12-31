import 'dart:convert' as cnv;
import 'dart:convert';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:parkingmap/dependency_injection.dart';
import 'package:parkingmap/services/auth_service.dart';
import '../model/marker_model.dart';
import '../model/parkingspot_model.dart';
import '../tools/app_config.dart';
import 'globals.dart' as globals;
import 'hive_service.dart';

typedef ParkingSpotData = ({
Marker mapMarker,
String address,
DateTime? timestamp,
double? probability,
int reports
});

class ParkingService{

  final AuthService _authService = getIt<AuthService>();
  final ValueNotifier<List<ParkingSpotData>> markersNotifier = ValueNotifier<List<ParkingSpotData>>([]);
  final markersBox = "markersBox";
  final cacheBox = "cacheBox";
  late final String? email = _authService.email;

  bool shouldUpdate = true;
  LatLngBounds? _lastKnownBounds;

  String tomTomApiKey = 'qa5MzxXesmBUxRLaWQnFRmMZ2D33kE7b';

  LatLngBounds? getLastKnownBounds() => _lastKnownBounds;

  Future<({bool success, String reason})> addLeaving(LocationData? location, String? token) async {
    try {
      if (location?.latitude == null || location?.longitude == null) {
        return (success: false, reason: 'Current location is not available.');
      }
      if (token == null) {
        return (success: false, reason: 'User is not authenticated.');
      }

      var userId = await _authService.getCurrentUserUID();
      var response = await http.post(
          Uri.parse('${AppConfig.instance.apiUrl}/add-leaving'),
          body: cnv.jsonEncode({
            "user_id": userId.toString(),
            "lat": location!.latitude!.toString(),
            "long": location.longitude!.toString(),
            "uid": token,
            "newParking": "false",
          }),
          headers: {
            "Content-Type": "application/json",
            "Authorization": globals.securityToken!
          });
      if (response.statusCode == 200) {
        if (_lastKnownBounds != null) {
          await getMarkersInBounds(_lastKnownBounds!, 15.0);
        }
        shouldUpdate = true;
        return (success: true, reason: 'Spot declared successfully.');
      }
      else if (response.statusCode == 429) {
        return (success: false, reason: 'Cooldown active. Please wait before declaring again.');
      } else {
        return (success: false, reason: 'Server error: ${response.statusCode}');
      }
    } catch (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
      return (success: false, reason: 'A network error occurred. Please check your connection.');
    }
  }

  Future<Response?> addSearching(LocationData? currentLocation) async {
    try {
      var userId = await AuthService().getCurrentUserUID();
      var response = await http.post(
          Uri.parse('${AppConfig.instance.apiUrl}/add-searching'),
          body: cnv.jsonEncode({
            "user_id": userId.toString(),
            "lat": currentLocation!.latitude!.toString(),
            "long": currentLocation!.longitude!.toString()
          }),
          headers: {
            "Content-Type": "application/json",
            "Authorization": globals.securityToken!
          });
      return response;
    } catch (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
      return null;
    }
  }

  // Function to check if current camera bounds are within expanded bounds
  bool isWithinExpandedBounds(
      LatLngBounds currentBounds, LatLngBounds expandedBounds) {
    // Check if the current bounds fit within the expanded bounds
    return (currentBounds.southWest.latitude >=
        expandedBounds.southWest.latitude &&
        currentBounds.southWest.longitude >=
            expandedBounds.southWest.longitude &&
        currentBounds.northEast.latitude <= expandedBounds.northEast.latitude &&
        currentBounds.northEast.longitude <=
            expandedBounds.northEast.longitude);
  }

  Future updateBounds(
      LatLngBounds bounds, double currentZoom) async {
    _lastKnownBounds = bounds;

    var cachedMarkers = await HiveService(markersBox).getAllCachedMarkers();
    var expandedBounds = await HiveService(cacheBox).getExpandedBoundsFromCache();

    bool needsNetworkFetch = (cachedMarkers.isEmpty && shouldUpdate) ||
        expandedBounds == null ||
        !isWithinExpandedBounds(bounds, expandedBounds) ||
        shouldUpdate;

    if (needsNetworkFetch) {
      shouldUpdate = false;
      postNewVisibleBounds(
          bounds.southWest.latitude,
          bounds.southWest.longitude,
          bounds.northEast.latitude,
          bounds.northEast.longitude,
          email);
      // Fetch markers asynchronously
      await getMarkersInBounds(bounds, currentZoom);
      var mappedSpots = markersNotifier.value.map((spotData) {
        return ParkingSpotModel(
            address: spotData.address,
            latitude: spotData.mapMarker.point.latitude,
            longitude: spotData.mapMarker.point.longitude,
            timestamp: spotData.timestamp,
            probability: spotData.probability);
      }).toList();
      await HiveService(markersBox).deleteAllCachedMarkers();
      await HiveService(markersBox).addMarkersToCache(mappedSpots);
      await HiveService(cacheBox).addExpandedBoundsToCache(bounds);
    }
    else {
      List<ParkingSpotData> spotsFromCache = List.empty(growable: true);
      for (var cmrk in cachedMarkers) {
        spotsFromCache.add(
            (
            mapMarker: cmrk.toMarker(),
            address: cmrk.address,
            timestamp: cmrk.timestamp,
            probability: cmrk.probability,
            reports: cmrk.reports
            )
        );
      }
      markersNotifier.value = spotsFromCache;
    }
    //   return cachedMarkers.map((marker) {
    //     return Marker(
    //         point: LatLng(marker.latitude, marker.longitude),
    //         child: Image.asset('Assets/Images/parking-location.png', scale: 18));
    //   }).toList();
  }

  Future<Response?> postNewVisibleBounds(
      swLat, swLong, neLat, neLong, userid) async {
    try {
      var response = await http.post(
          Uri.parse('${AppConfig.instance.apiUrl}/update-bounds'),
          body: cnv.jsonEncode({
            "email": email,
            "sw_lat": swLat.toString(),
            "sw_long": swLong.toString(),
            "ne_lat": neLat.toString(),
            "ne_long": neLong.toString()
          }),
          headers: {
            "Content-Type": "application/json",
            "Authorization": globals.securityToken!
          });
      return response;
    } catch (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
      return null;
    }
  }

  Future getMarkersInBounds(
      LatLngBounds bounds, double currentZoom) async {
    try {
      print("1. [getMarkersInBounds] Fetching markers for bounds: $bounds");
      final url =
          '${AppConfig.instance.apiUrl}/markers?swLat=${bounds.southWest.latitude}&swLng=${bounds.southWest.longitude}&neLat=${bounds.northEast.latitude}&neLng=${bounds.northEast.longitude}';

      final response = await http.get(Uri.parse(url),
          headers: {"Authorization": globals.securityToken!});

      if (response.statusCode == 200) {
        if(response.body.isEmpty){
          markersNotifier.value = [];
          return;
        }

        var decodedResponse = json.decode(response.body);
        List<dynamic> markersData = [];

        if (decodedResponse is Map<String, dynamic> && decodedResponse['data'] != null) {
          markersData = decodedResponse['data'];
        } else if (decodedResponse is List) {
          // Fallback in case the API sometimes returns a direct list
          markersData = decodedResponse;
        }
        print("2. [getMarkersInBounds] API call successful. Received ${markersData.length} raw markers.");

        // Manually create Marker objects from the response
        List<ParkingSpotData> markers = markersData.map((data) {
          return (
          mapMarker: Marker(
            width: 80.0,
            height: 80.0,
            point: LatLng(data['latitude'], data['longitude']),
            child: Image.asset('Assets/Images/parking-location.png', scale: 18),
          ),
          address: data['address'].toString() ?? 'Address Not Available',
          timestamp: DateTime.parse(data['time'] ?? DateTime.now().toIso8601String()),
          probability: (data['probability'] as num?)?.toDouble() ?? 0.0,
          reports: (data['reports'] as int?) ?? 0,
          );
        }).toList();

        var mappedSpots = markers.map((spot) {
          return ParkingSpotModel(
              address: spot.address,
              latitude: spot.mapMarker.point.latitude,
              longitude: spot.mapMarker.point.longitude,
              timestamp: spot.timestamp,
              probability: spot.probability
          );
        }).toList();

        markersNotifier.value = markers;
        HiveService("markersBox").addMarkersToCache(mappedSpots);
        print("3. [getMarkersInBounds] Notifier updated with ${markers.length} markers.");

      } else {
        print("2. [getMarkersInBounds] API call FAILED with status: ${response.statusCode}");

        markersNotifier.value = [];
      }
    } catch (error, stackTrace) {
      print("2. [getMarkersInBounds] Exception caught: $error");
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
      markersNotifier.value = [];
    }
  }

  void addMarkerFromNotification(LatLng point, String address) {// 1. Get the current list of markers from the notifier.
    final currentSpots = List<ParkingSpotData>.from(markersNotifier.value);

    // 2. Check if a marker at this point already exists to avoid duplicates.
    final markerExists = currentSpots.any((spot) => spot.mapMarker.point == point);
    if (markerExists) {
      print("Marker at $point already exists. Not adding from notification.");
      return;
    }

    // 3. Create the new marker.
    final newSpot = (
    mapMarker: Marker(
      width: 80.0,
      height: 80.0,
      point: point,
      child: Image.asset('Assets/Images/parking-location.png', scale: 18),
    ),
    timestamp: DateTime.now(),
    probability: 0.75,
    address: address,
    reports: 0,
    );

    // 4. Add the new marker to the list.
    currentSpots.add(newSpot);

    // 5. Update the notifier with the new, modified list. This will trigger the UI to rebuild.
    markersNotifier.value = currentSpots;
    var mappedSpots = currentSpots.map((spot) {
      return ParkingSpotModel(
          address: spot.address,
          latitude: spot.mapMarker.point.latitude,
          longitude: spot.mapMarker.point.longitude,
          timestamp: spot.timestamp,
          probability: spot.probability
          );
    }).toList();
    HiveService("markersBox").addMarkersToCache(mappedSpots);

    print("Added marker from notification at $point. Total markers: ${mappedSpots.length}");
  }

  Future<Response?> deleteMarker(Marker marker, String topic, String uid) async {
    try {
      var response = await http.post(
          Uri.parse("${AppConfig.instance.apiUrl}/delete-marker"),
          body: cnv.jsonEncode({
            "latitude": marker.point.latitude.toString(),
            "longitude": marker.point.longitude.toString(),
            "topic": topic,
            "uid": uid
          }),
          headers: {
            "Content-Type": "application/json",
            "Authorization": globals.securityToken!
          });

      if (response.statusCode == 200){
        getMarkersInBounds(_lastKnownBounds!, 15.0);
      }

      return response;
    } catch (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
      return null;
    }
  }

  Future<bool> incrementReport(double latitude, double longitude) async {
    try {
      var uid = await _authService.getCurrentUserUID();
      var response = await http.post(
          Uri.parse("${AppConfig.instance.apiUrl}/increment-report"),
          body: cnv.jsonEncode({
            "latitude": latitude.toString(),
            "longitude": longitude.toString(),
            "user_id": uid
          }),
          headers: {
            "Content-Type": "application/json",
            "Authorization": globals.securityToken!
          });

      if (response.statusCode == 200){
        if (_lastKnownBounds != null) {
          await getMarkersInBounds(_lastKnownBounds!, 15.0);
        }
        shouldUpdate = true;
        return true;
      } else{
        return false;
      }
    } catch (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
      return false;
    }
  }

  // NEW METHOD for removing a marker from a notification
  void removeMarkerFromNotification(LatLng point) {
    // 1. Get the current list of markers.
    final currentMarkers = List<ParkingSpotData>.from(markersNotifier.value);

    // 2. Remove any markers that match the specified point.
    currentMarkers.removeWhere((parkingSpot) => parkingSpot.mapMarker.point == point);

    // 3. Update the notifier with the new, modified list.
    markersNotifier.value = currentMarkers;
    print("Removed marker from notification at $point. Total markers: ${currentMarkers.length}");
  }

  Future<Response?> getSearchingCount(double latitude, double longitude) async {
    try {
      var response = await http.get(
          Uri.parse("${AppConfig.instance.apiUrl}/search/count?latitude=${latitude.toString()}&longitude=${longitude.toString()}"),
          headers: {
            "Authorization": globals.securityToken!
          });
      print(response.body);
      return response;
    } catch (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
      return null;
    }
  }

  // Future<String?> convertPointToAddress(LatLng marker) async {
  //   try {
  //     //if (!convertedToAddress) {
  //     //convertedToAddress = true;
  //     var response = await http.get(Uri.parse(
  //         'https://api.tomtom.com/maps/orbis/places/reverseGeocode/${marker.latitude},${marker.longitude}.json?key=$tomTomApiKey&apiVersion=1'));
  //     if (response.statusCode == 200) {
  //       //convertedToAddress = false;
  //       var decodedResponse = cnv.utf8.decode(response.bodyBytes);
  //       addressCache[marker] = decodedResponse;
  //       return response.body;
  //     } else {
  //       return null;
  //     }
  //     //} else {
  //     //  return null;
  //     //}
  //   } catch (e) {
  //     return null;
  //   }
  // }
  // Future<String?> convertPointToAddress(LatLng marker) async {
  //   try {
  //     final response = await http.post(
  //       Uri.parse('${AppConfig.instance.apiUrl}/convert-point-address'),
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'Authorization': globals.securityToken!,
  //       },
  //       body: jsonEncode({
  //         'latitude': marker.latitude,
  //         'longitude': marker.longitude,
  //       }),
  //     );
  //
  //     if (response.statusCode == 200) {
  //       final decoded = jsonDecode(utf8.decode(response.bodyBytes));
  //       addressCache[marker] = decoded;
  //       return jsonEncode(decoded['data']);
  //     }
  //
  //     return null;
  //   } catch (e) {
  //     return null;
  //   }
  // }

}