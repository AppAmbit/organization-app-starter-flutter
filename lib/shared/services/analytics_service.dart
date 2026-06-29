import 'package:appambit_sdk_flutter/appambit_sdk_flutter.dart';

class AnalyticsService {
  static void trackEvent(String name, Map<String, dynamic> properties) {
    AppAmbitSdk.trackEvent(
      name,
      properties.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  static void trackResourceOpened({required String url, required String label}) =>
      trackEvent('Resource Opened', {'url': url, 'label': label});

  static void trackNotificationOpened({
    required String title,
    required String body,
  }) =>
      trackEvent('Notification Opened', {'title': title, 'body': body});
}
