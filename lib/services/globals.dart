library parkingmap.globals;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:parkingmap/screens/login.dart';
import 'package:parkingmap/tools/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as cnv;
import 'package:parkingmap/services/auth_service.dart';
import 'package:toastification/toastification.dart';

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
  } catch (error, stackTrace) {
    FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }
}

deleteLeaving(int latestLeavingID) async {
  try {
    await http.delete(Uri.parse("${AppConfig.instance.apiUrl}/delete-leaving"),
        body: cnv.jsonEncode({"leavingID": latestLeavingID}),
        headers: {"Content-Type": "application/json"});
  } catch (error, stackTrace) {
    FirebaseCrashlytics.instance.recordError(error, stackTrace);
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
        headers: {
          "Content-Type": "application/json",
          "Authorization": securityToken!
        });
  } catch (error, stackTrace) {
    FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }
}

getPoints() async {
  final prefs = await SharedPreferences.getInstance();
  var userId = prefs.getString('userid');
  try {
    await http.post(Uri.parse("${AppConfig.instance.apiUrl}/get-points"),
        body: cnv.jsonEncode({"user_id": userId}),
        headers: {
          "Content-Type": "application/json",
          "Authorization": securityToken!
        });
  } catch (error, stackTrace) {
    FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }
}

updatePoints(int? updatedPoints) async {
  final prefs = await SharedPreferences.getInstance();
  var userId = prefs.getString('userid');
  try {
    await http.post(Uri.parse("${AppConfig.instance.apiUrl}/update-points"),
        body: cnv.jsonEncode({"user_id": userId, "points": updatedPoints}),
        headers: {
          "Content-Type": "application/json",
          "Authorization": securityToken!
        });
  } catch (error, stackTrace) {
    FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }
}

// Function to sign out the user
Future<void> signOutAndNavigate(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear(); // Clear all saved data
  AuthService().signOut();
  if (!context.mounted) return;
  // Navigate to the login page and remove all previous routes
  await Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (context) => const LoginPage()),
    (Route<dynamic> route) => false,
  );
}

showSoonToComeToast(BuildContext context) {
  toastification.show(
    context: context,
    type: ToastificationType.info,
    style: ToastificationStyle.flat,
    title: const Text("Soon to come!"),
    alignment: Alignment.bottomCenter,
    autoCloseDuration: const Duration(seconds: 4),
    borderRadius: BorderRadius.circular(100.0),
    boxShadow: lowModeShadow,
  );
}
