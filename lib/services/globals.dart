library;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:parkingmap/enums/cooldown_type_enum.dart';
import 'package:parkingmap/screens/login.dart';
import 'package:parkingmap/services/hive_service.dart';
import 'package:parkingmap/tools/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as cnv;
import 'package:parkingmap/services/auth_service.dart';
import 'package:toastification/toastification.dart';

import '../dependency_injection.dart';

AuthService _authService = getIt<AuthService>();
bool premiumSearchState = false;
bool searching = false;
String? securityToken = "";
String points = "0";
String? fcmToken = "";
String? uid = "";
SharedPreferences? sharedPreferences;

Future initializeSharedPreferences() async {
  sharedPreferences = await SharedPreferences.getInstance();
}

Future initializeUid() async {
  uid = await _authService.getCurrentUserUID();
}

Future getDevToken() async {
  fcmToken = await FirebaseMessaging.instance.getToken();
}

Future initializeSecurityToken() async {
  AuthService().getCurrentUserIdToken().then(
    (value) {
      securityToken = value;
    },
  );
}

Future initializePoints() async {
  HiveService("").getPointsFromCache().then(
    (value) {
      points = value;
    },
  );
}

Future initializePremiumSearchState() async {
  HiveService("").getPremiumSearchStateFromCache().then(
    (value) {
      premiumSearchState = value;
    },
  );
}

Future<void> cancelSearch() async {
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

Future<void> deleteLeaving(int latestLeavingID) async {
  try {
    await http.delete(Uri.parse("${AppConfig.instance.apiUrl}/delete-leaving"),
        body: cnv.jsonEncode({"leavingID": latestLeavingID}),
        headers: {"Content-Type": "application/json"});
  } catch (error, stackTrace) {
    FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }
}

Future<void> postSkip(timesSkipped, time, latitude, longitude, latestLeavingID) async {
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

Future<void> getPoints() async {
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

Future getLastActionTime(CooldownType cooldownType) async {
  var lastActionTime = cooldownType == CooldownType.report ? sharedPreferences?.getString('lastReportTime') : sharedPreferences?.getString('lastDeclareTime');

  if(lastActionTime == null || lastActionTime.isEmpty) {
    lastActionTime = cooldownType == CooldownType.report ? await fetchLastReportTime(uid!) : await fetchLastDeclareTime(uid!);
    cooldownType == CooldownType.report ? sharedPreferences?.setString('lastReportTime', lastActionTime) : sharedPreferences?.setString('lastDeclareTime', lastActionTime);
  }

  return lastActionTime;
}

Future<DateTime?> getLastActionDateTime(CooldownType cooldownType) async {
  var timeStr = await getLastActionTime(cooldownType); // Returns String like "2023-10-27T10:00:00.000Z" or ""

  if (timeStr != null && timeStr is String && timeStr.isNotEmpty) {
    return DateTime.tryParse(timeStr);
  }
  return null;
}

// 1. Get Duration SINCE the last report (Time Elapsed)
// Future<Duration> getTimeSinceLastReport() async {
//   DateTime? lastReport = await getLastReportDateTime();
//   if (lastReport == null) {
//     return Duration.zero; // Or a very large duration if "never" means infinite time
//   }
//   return DateTime.now().difference(lastReport);
// }

// 2. Get Duration REMAINING for a cooldown (e.g., 5 minutes)
Future<Duration> getRemainingCooldown(Duration cooldownDuration, CooldownType cooldownType) async {
  DateTime? lastAction = await getLastActionDateTime(cooldownType);
  if (lastAction == null) {
    return Duration.zero; // No previous report, so 0 cooldown remaining
  }

  final difference = DateTime.now().difference(lastAction);

  if (difference < cooldownDuration) {
    return cooldownDuration - difference;
  } else {
    return Duration.zero; // Cooldown has passed
  }
}

Future<String> fetchLastReportTime(String userId) async {
  try{
    var response = await http.get(Uri.parse("${AppConfig.instance.apiUrl}/user-last-report-time?user_id=$userId"),
        headers: {
          "Authorization": securityToken!
        });
    if(response.statusCode == 200){
      final decodedBody = cnv.jsonDecode(response.body);
      if (decodedBody is Map<String, dynamic> && decodedBody.containsKey('last_report_time')) {
        return decodedBody['last_report_time'] as String;
      }

      // Fallback if the backend sends just the string "..."
      if (decodedBody is String) {
        return decodedBody;
      }
    }
  }
  catch (error, stackTrace) {
    FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }
  return "";
}

Future<String> fetchLastDeclareTime(String userId) async {
  try{
    var response = await http.get(Uri.parse("${AppConfig.instance.apiUrl}/user-last-declare-time?user_id=$userId"),
        headers: {
          "Authorization": securityToken!
        });
    if(response.statusCode == 200){
      final decodedBody = cnv.jsonDecode(response.body);
      if (decodedBody is Map<String, dynamic> && decodedBody.containsKey('last_declare_time')) {
        return decodedBody['last_declare_time'] as String;
      }

      // Fallback if the backend sends just the string "..."
      if (decodedBody is String) {
        return decodedBody;
      }
    }
  }
  catch (error, stackTrace) {
    FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }
  return "";
}

// Function to sign out the user
Future<void> signOutAndNavigate(BuildContext context,
    {bool? accountDeleted}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear(); // Clear all saved data
  AuthService().signOut();
  if (!context.mounted) return;
  // Navigate to the login page and remove all previous routes
  await Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(
        builder: (context) =>
            LoginPage(accountDeleted: accountDeleted ?? false)),
    (Route<dynamic> route) => false,
  );
}

void showSoonToComeToast(BuildContext context) {
  toastification.show(
      context: context,
      type: ToastificationType.info,
      style: ToastificationStyle.flat,
      title: const Text("Soon to come!"),
      alignment: Alignment.bottomCenter,
      autoCloseDuration: const Duration(seconds: 4),
      borderRadius: BorderRadius.circular(100.0),
      boxShadow: lowModeShadow,
      showProgressBar: false);
}

void showServerErrorToast(BuildContext context) {
  toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.flat,
      title: const Text("There was a server error"),
      alignment: Alignment.bottomCenter,
      autoCloseDuration: const Duration(seconds: 4),
      borderRadius: BorderRadius.circular(100.0),
      boxShadow: lowModeShadow,
      showProgressBar: false);
}

void showSuccessfullToast(BuildContext context, String message) {
  toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flat,
      title: Text(message),
      alignment: Alignment.bottomCenter,
      autoCloseDuration: const Duration(seconds: 4),
      borderRadius: BorderRadius.circular(100.0),
      boxShadow: lowModeShadow,
      showProgressBar: false);
}

void showToast(BuildContext context, String message, ToastificationType type) {
  toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flat,
      title: Text(message),
      alignment: Alignment.bottomCenter,
      autoCloseDuration: const Duration(seconds: 4),
      borderRadius: BorderRadius.circular(100.0),
      boxShadow: lowModeShadow,
      showProgressBar: false);
}