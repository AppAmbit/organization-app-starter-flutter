import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static late final String _appKeyIos;
  static late final String _appKeyAndroid;

  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
    _appKeyIos = dotenv.env['APPAMBIT_APPKEY_IOS'] ?? '';
    _appKeyAndroid = dotenv.env['APPAMBIT_APPKEY_ANDROID'] ?? '';
  }

  static String get appKey =>
      Platform.isIOS ? _appKeyIos : _appKeyAndroid;
}
