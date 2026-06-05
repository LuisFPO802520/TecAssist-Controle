import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiClient {
  static String get baseUrl {
    if (kIsWeb) {
      return dotenv.env['API_URL_WEB']!;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return dotenv.env['API_URL_EMULATOR']!;
    }

    return dotenv.env['API_URL_PHYSICAL']!;
  }

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );
}
