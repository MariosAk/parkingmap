import 'dart:convert' as cnv;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;

import '../dependency_injection.dart';
import '../tools/app_config.dart';
import 'auth_service.dart';
import 'globals.dart' as globals;

class UserService{

  final AuthService _authService = getIt<AuthService>();
  late final String? email = _authService.email;

  Future<Response?> deleteUser(String? userID) async {
    try {
      if (userID != null) {
        var response = await http.delete(
            Uri.parse("${AppConfig.instance.apiUrl}/delete-user"),
            body: cnv.jsonEncode({"userID": userID}),
            headers: {
              "Content-Type": "application/json",
              "Authorization": globals.securityToken!
            });
        return response;
      } else {
        return null;
      }
    } catch (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
      return null;
    }
  }

  Future<void> registerCar(String carType, String? email) async {
    try {
      await http.post(Uri.parse("${AppConfig.instance.apiUrl}/register-car"),
          body: cnv.jsonEncode({"carType": carType, "email": email}),
          headers: {
            "Content-Type": "application/json",
            "Authorization": globals.securityToken!
          });
    } catch (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    }
  }

  Future registerUser(uid, email, fcmToken) async {
    try {
      var response = await http.post(
          Uri.parse("${AppConfig.instance.apiUrl}/register-user"),
          body: cnv.jsonEncode({
            "uid": uid,
            "email": email,
            "fcm_token": fcmToken
          }),
          headers: {
            "Content-Type": "application/json",
            "Authorization": globals.securityToken!
          });
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    }
  }

  // Future sendAlive(String deviceId, double latitude, double longitude) async {
  //   try {
  //     await http.post(
  //         Uri.parse("${AppConfig.instance.apiUrl}/search/heartbeat"),
  //         body: cnv.jsonEncode({
  //           "deviceId": deviceId,
  //           "latitude": latitude.toString(),
  //           "longitude": longitude.toString(),
  //         }),
  //         headers: {
  //           "Content-Type": "application/json",
  //           "Authorization": globals.securityToken!
  //         });
  //   } catch (error, stackTrace) {
  //     FirebaseCrashlytics.instance.recordError(error, stackTrace);
  //   }
  // }

  Future postInterestInPremium() async {
    try {
      var response = await http.post(
          Uri.parse('${AppConfig.instance.apiUrl}/register-premium-interest'),
          body: cnv.jsonEncode({
            "email": email
          }),
          headers: {
            "Content-Type": "application/json",
            "Authorization": globals.securityToken!
          });
      if (response.statusCode == 200) {
        globals.sharedPreferences?.setBool('isInterestedInPremium', true);
        return true;
      } else {
        return false;
      }
    } catch (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
      return null;
    }
  }

}