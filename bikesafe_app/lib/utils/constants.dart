import 'dart:io';

class Constants {
  static const bool isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);

  static String get envBaseUrl {
    if (Platform.isAndroid || Platform.isIOS) {
      return isProduction ? 'https://api.bikesafeapp.com/api' : 'http://192.168.1.244:5001/api';
    } else {
      return isProduction ? 'https://api.bikesafeapp.com/api' : 'http://localhost:5001/api';
    }
  }
}