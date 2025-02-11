import 'package:flutter_map/flutter_map.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:parkingmap/model/latlng_bounds_model.dart';
import 'package:parkingmap/model/marker_model.dart';
import 'package:parkingmap/services/points_service.dart';

class HiveService {
  final _markersboxName = "markersBox";
  final _cacheboxName = "cacheBox";
  static final HiveService _instance = HiveService._internal();
  final pointsService = PointsService();

  HiveService._internal();

  factory HiveService(String boxName) {
    return _instance;
  }

  Future<Box<List>> get _markerBox async => Hive.box(_markersboxName);
  Future<Box> get _cacheBox async => Hive.box(_cacheboxName);

//create
  Future<void> addMarkersToCache(List<MarkerModel> markers) async {
    var box = await _markerBox;
    await box.put("cachedMarkers", markers);
  }

  //read
  Future getAllCachedMarkers() async {
    var box = await _markerBox;
    //await box.clear();
    return box.get("cachedMarkers", defaultValue: List.empty());
  }

  Future<void> addExpandedBoundsToCache(LatLngBounds bounds) async {
    var box = await _cacheBox;
    final boundsModel = LatLngBoundsModel(
        neLat: bounds.northEast.latitude + 0.004,
        neLng: bounds.northEast.longitude + 0.004,
        swLat: bounds.southWest.latitude - 0.004,
        swLng: bounds.southWest.longitude - 0.004);
    await box.put("expandedBounds", boundsModel);
  }

  Future<LatLngBounds?> getExpandedBoundsFromCache() async {
    var box = await _cacheBox;
    final bounds = box.get("expandedBounds");
    if (bounds != null) {
      return LatLngBoundsModel(
              swLat: bounds.swLat,
              swLng: bounds.swLng,
              neLat: bounds.neLat,
              neLng: bounds.neLng)
          .toLatLngBounds();
    }
    return null;
  }

//update
  Future<void> updateCache(int index, List<MarkerModel> markers) async {
    var box = await _markerBox;
    await box.putAt(index, markers);
  }

//delete specific
  Future<void> deleteCachedMarker(MarkerModel marker) async {
    var box = await _markerBox;
    List<MarkerModel> list =
        List<MarkerModel>.from(await getAllCachedMarkers());
    var markerToDelete = list
        .where((element) =>
            element.latitude == marker.latitude &&
            element.longitude == marker.longitude)
        .firstOrNull;
    list.remove(markerToDelete);
    await box.put("cachedMarkers", list);
    //await box.deleteAt(index);
  }

  //delete all
  Future<void> deleteAllCachedMarkers() async {
    var box = await _markerBox;
    await box.delete("cachedMarkers");
    await box.put("cachedMarkers", List<MarkerModel>.empty(growable: true));
  }

  Future<void> addPointsToCache(String points) async {
    var box = await _cacheBox;
    var encryptedPoints = await pointsService.encryptPoints(points);
    await box.put("points", encryptedPoints);
  }

  Future<String> getPointsFromCache() async {
    var box = await _cacheBox;
    final encryptedPoints = box.get("points");
    if (encryptedPoints != null) {
      var points = pointsService.decryptPoints(encryptedPoints);
      return points;
    }
    return "0";
  }

  Future<void> setPremiumSearchStateToCache(bool state) async {
    var box = await _cacheBox;
    var strState = state.toString();
    await box.put("premiumSearchState", strState);
  }

  Future<bool> getPremiumSearchStateFromCache() async {
    var box = await _cacheBox;
    var strState = box.get("premiumSearchState").toString();
    if (strState.isNotEmpty && strState != "null") {
      return bool.parse(strState);
    } else {
      return false;
    }
  }
}
