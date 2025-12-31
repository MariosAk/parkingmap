import 'package:flutter/foundation.dart';

class AppConfig {
  static final AppConfig _instance = AppConfig._internal();

  // Variables for your configuration
  final String apiUrl;

  // Private constructor
  AppConfig._internal()
      : apiUrl = kReleaseMode
            ? 'https://parking-backend-gmj3.onrender.com'
            : 'http://192.168.1.64:3000';

  // Getter to access the instance
  static AppConfig get instance => _instance;
}
