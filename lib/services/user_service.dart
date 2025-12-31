import 'dart:convert' as cnv;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;

import '../tools/app_config.dart';
import 'globals.dart' as globals;

class UserService{

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

  Future registerUser(uid, email, password, fcmToken) async {
    try {
      var response = await http.post(
          Uri.parse("${AppConfig.instance.apiUrl}/register-user"),
          body: cnv.jsonEncode({
            "uid": uid,
            "email": email,
            "password": password,
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

  Future sendAlive(String deviceId, double latitude, double longitude) async {
    try {
      await http.post(
          Uri.parse("${AppConfig.instance.apiUrl}/search/heartbeat"),
          body: cnv.jsonEncode({
            "deviceId": deviceId,
            "latitude": latitude.toString(),
            "longitude": longitude.toString(),
          }),
          headers: {
            "Content-Type": "application/json",
            "Authorization": globals.securityToken!
          });
    } catch (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    }
  }

}