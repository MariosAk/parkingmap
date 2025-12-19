import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:parkingmap/services/globals.dart' as globals;
import 'package:http/http.dart' as http;
import '../dependency_injection.dart';
import '../tools/app_config.dart';
import 'auth_service.dart';
import 'dart:convert' as cnv;

class InitService {
  final AuthService _authService = getIt<AuthService>();

  Future registerFcmToken() async {
    try {
      var token = await _authService.getCurrentUserIdToken();
      await globals.getDevToken();
      var userId = token;
      http.post(Uri.parse("${AppConfig.instance.apiUrl}/register-fcmToken"),
          body: cnv.jsonEncode(
              {"user_id": userId.toString(), "fcmtoken": globals.fcmToken.toString()}),
          headers: {
            "Content-Type": "application/json",
            "Authorization": globals.securityToken!
          });
    } catch (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    }
  }

}