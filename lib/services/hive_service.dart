import 'package:flutter_map/flutter_map.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:parkingmap/model/latlng_bounds_model.dart';
import 'package:parkingmap/model/marker_model.dart';

class HiveService {
  final _markersboxName = "markersBox";
  final _cacheboxName = "cacheBox";
  static final HiveService _instance = HiveService._internal();

  HiveService._internal();

  factory HiveService(String boxName) {
    return _instance;
  }

  Future<Box<List>> get _markerBox async => Hive.box(_markersboxName);
  Future<Box> get _cacheBox async => Hive.box(_cacheboxName);

//create
  Future<void> addMarkersToCache(List<MarkerModel> markers) async {
    var box = await _markerBox;
    await box.add(markers);
  }

  //read
  Future getAllCachedMarkers() async {
    var box = await _markerBox;
    //await box.clear();
    return box.values.toList();
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
  Future<void> deleteCachedMarker(int index) async {
    var box = await _markerBox;
    await box.deleteAt(index);
  }

  //delete all
  Future<void> deleteAllCachedMarkers() async {
    var box = await _markerBox;
    await box.clear();
  }
}
