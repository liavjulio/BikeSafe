import 'dart:io';

class Constants {
  static String get apiBaseUrl {
    if (Platform.isAndroid || Platform.isIOS) {
      return 'http://192.168.1.244:5001/api'; // ✅ Your mobile network IP
    } else {
      return 'http://localhost:5001/api'; // ✅ For web or desktop
    }
  }

  // Optional: If you want to switch environments
  static const bool isProduction = false;

  static String get envBaseUrl {
    return isProduction
        ? 'https://api.bikesafeapp.com/api' // Production API
        : apiBaseUrl;                       // Development API
  }
}