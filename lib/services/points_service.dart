import 'package:encrypt/encrypt.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:parkingmap/services/auth_service.dart';
import 'package:parkingmap/services/hive_service.dart';
import 'package:parkingmap/tools/app_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as cnv;
import 'encryption_service.dart';
import 'globals.dart';

class PointsService {
  Future<String> encryptPoints(String data) async {
    final encryptionService = EncryptionService();
    final key = await encryptionService.getEncryptionKey();
    final encrypter = Encrypter(AES(key));
    final iv = IV.fromSecureRandom(16); // Initialization vector for security

    final encrypted = encrypter.encrypt(data, iv: iv);

    // Store both IV and encrypted data as a single string
    return '${iv.base64}:${encrypted.base64}';
  }

  Future<String> decryptPoints(String encryptedData) async {
    final encryptionService = EncryptionService();
    final key = await encryptionService.getEncryptionKey();
    final encrypter = Encrypter(AES(key));

    // Split the IV and the actual encrypted data
    final parts = encryptedData.split(':');
    final iv = IV.fromBase64(parts[0]);
    final encrypted = Encrypted.fromBase64(parts[1]);

    return encrypter.decrypt(encrypted, iv: iv);
  }

  Future updatePoints() async {
    var intPoints = int.tryParse(points);
    if (intPoints != null) {
      var updatedPoints = (intPoints + 10).toString();
      HiveService("").addPointsToCache(updatedPoints);
      points = updatedPoints;
      updatePointsDB(intPoints + 10);
    }
  }

  updatePointsDB(int? updatedPoints) async {
    var userId = await AuthService().getCurrentUserUID();
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
}
