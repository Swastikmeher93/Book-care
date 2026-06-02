import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  /// The base URL of the FastAPI backend server.
  /// 
  /// In an Android emulator, `localhost` (127.0.0.1) refers to the emulator itself.
  /// The host machine's loopback interface is mapped to `10.0.2.2`.
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8000';
      }
    } catch (_) {
      // fallback in case Platform is not supported on a platform (like web)
    }
    return 'http://localhost:8000';
  }
}
