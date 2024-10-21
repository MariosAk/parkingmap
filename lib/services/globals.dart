library parkingmap.globals;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:parkingmap/screens/login.dart';
import 'package:parkingmap/tools/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as cnv;
import 'package:parkingmap/services/auth_service.dart';
import 'package:parkingmap/services/auth_service.dart';

bool heroOverlay = false;
bool searching = false;
String? securityToken = "";

Future initializeSecurityToken() async {
  AuthService().getCurrentUserIdToken().then(
    (value) {
      securityToken = value;
    },
  );
}

cancelSearch() async {
  final prefs = await SharedPreferences.getInstance();
  var userId = prefs.getString('userid');
  try {
    await http.delete(Uri.parse('${AppConfig.instance.apiUrl}/cancel-search'),
        body: cnv.jsonEncode({"user_id": userId}),
        headers: {"Content-Type": "application/json"});
  } catch (e) {
    print(e);
  }
}

deleteLeaving(int latestLeavingID) async {
  try {
    await http.delete(Uri.parse("${AppConfig.instance.apiUrl}/delete-leaving"),
        body: cnv.jsonEncode({"leavingID": latestLeavingID}),
        headers: {"Content-Type": "application/json"});
  } catch (e) {
    print(e);
  }
}

postSkip(timesSkipped, time, latitude, longitude, latestLeavingID) async {
  try {
    await http.post(Uri.parse("${AppConfig.instance.apiUrl}/parking-skipped"),
        body: cnv.jsonEncode({
          "times_skipped": timesSkipped,
          "time": time,
          "latitude": latitude,
          "longitude": longitude,
          "latestLeavingID": latestLeavingID
        }),
        headers: {"Content-Type": "application/json"});
  } catch (e) {}
}

getPoints() async {
  final prefs = await SharedPreferences.getInstance();
  var userId = prefs.getString('userid');
  try {
    await http.post(Uri.parse("${AppConfig.instance.apiUrl}/get-points"),
        body: cnv.jsonEncode({"user_id": userId}),
        headers: {"Content-Type": "application/json"});
  } catch (e) {
    print(e);
  }
}

updatePoints(int? updatedPoints) async {
  final prefs = await SharedPreferences.getInstance();
  var userId = prefs.getString('userid');
  try {
    await http.post(Uri.parse("${AppConfig.instance.apiUrl}/update-points"),
        body: cnv.jsonEncode({"user_id": userId, "points": updatedPoints}),
        headers: {"Content-Type": "application/json"});
  } catch (e) {
    print(e);
  }
}

// Function to sign out the user
Future<void> signOutAndNavigate(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear(); // Clear all saved data
  AuthService().signOut();

  // Navigate to the login page and remove all previous routes
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (context) => const LoginPage()),
    (Route<dynamic> route) => false,
  );
}
