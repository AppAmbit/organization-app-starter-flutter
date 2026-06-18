import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:organization_app_starter/features/notifications/models/notification_model.dart';

/// Bridges the iOS Notification Service Extension to the Flutter app.
///
/// The NSE runs in a separate process and writes background notifications into
/// a shared App Group `UserDefaults` queue. This drains that queue (read +
/// clear) over a MethodChannel implemented in `AppDelegate.swift`, so the
/// records can be merged into the Dart store on app resume.
///
/// No-op on Android (Android background uses the Dart background isolate).
class IosNotificationBridge {
  static const MethodChannel _channel =
      MethodChannel('org.app/notifications_ios');

  /// Returns and clears the pending notifications saved by the NSE.
  static Future<List<NotificationModel>> drainPending() async {
    if (!Platform.isIOS) return const [];
    try {
      final result =
          await _channel.invokeMethod<List<dynamic>>('drainPending');
      if (result == null) return const [];
      return result
          .whereType<Map>()
          .map((m) => NotificationModel.fromMap(
              m.map((k, v) => MapEntry(k.toString(), v))))
          .toList();
    } on PlatformException catch (e) {
      debugPrint('[IosNotificationBridge] PlatformException: $e');
      return const [];
    } on MissingPluginException catch (e) {
      debugPrint('[IosNotificationBridge] MissingPluginException: $e');
      return const [];
    }
  }
}
