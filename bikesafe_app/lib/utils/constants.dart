import 'dart:io';

class Constants {
  static const bool isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);

  static String get envBaseUrl {
    if (Platform.isAndroid || Platform.isIOS) {
      return isProduction ? 'https://bikesafe-backend-latest.onrender.com/api' : 'https://bikesafe-backend-latest.onrender.com/api';
    } else {
      return isProduction ? 'https://bikesafe-backend-latest.onrender.com/api' : 'https://bikesafe-backend-latest.onrender.com/api';
    }
  }
}