import 'dart:convert';

import 'package:appambit_sdk_push_notifications/appambit_sdk_push_notifications.dart';

/// A persisted in-app notification.
///
/// This is the canonical record stored in SharedPreferences and rendered by
/// the notifications list. It is intentionally serialization-friendly: the icon
/// is kept as a backend string key ([iconKey]) and resolved to a Material
/// `IconData` only at render time via `iconFor` in `notification_icons.dart`.
class NotificationModel {
  /// Stable id from the push payload (`notification_id`). Used for dedup and
  /// read-state. Falls back to [receivedAt] when the backend omits it.
  final String id;
  final String title;
  final String message;

  /// Backend icon name (e.g. "article"). Resolved to an `IconData` at render
  /// time. NOT the system tray icon.
  final String? iconKey;

  /// When this notification was received, epoch milliseconds.
  final int receivedAt;

  final bool read;

  /// Push notification image URL delivered by the SDK.
  final String? imageUrl;

  /// Navigation hint consumed by the opened-listener (e.g. "content_detail").
  final String? route;

  /// Entity id used together with [route] (e.g. the content id to open).
  final String? contentId;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.receivedAt,
    this.iconKey,
    this.imageUrl,
    this.read = false,
    this.route,
    this.contentId,
  });

  NotificationModel copyWith({bool? read, int? receivedAt}) => NotificationModel(
        id: id,
        title: title,
        message: message,
        receivedAt: receivedAt ?? this.receivedAt,
        iconKey: iconKey,
        imageUrl: imageUrl,
        read: read ?? this.read,
        route: route,
        contentId: contentId,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'message': message,
        'iconKey': iconKey,
        'imageUrl': imageUrl,
        'receivedAt': receivedAt,
        'read': read,
        'route': route,
        'contentId': contentId,
      };

  factory NotificationModel.fromMap(Map<String, dynamic> map) =>
      NotificationModel(
        id: (map['id'] ?? '').toString(),
        title: (map['title'] ?? '').toString(),
        message: (map['message'] ?? '').toString(),
        iconKey: map['iconKey'] as String?,
        imageUrl: map['imageUrl'] as String?,
        receivedAt: (map['receivedAt'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
        read: map['read'] == true,
        route: map['route'] as String?,
        contentId: map['contentId'] as String?,
      );

  String toJson() => jsonEncode(toMap());

  factory NotificationModel.fromJson(String source) =>
      NotificationModel.fromMap(jsonDecode(source) as Map<String, dynamic>);

  /// Builds a record from a [PushNotificationData] delivered by the SDK.
  ///
  /// Reads the agreed-upon backend keys from [PushNotificationData.data]:
  /// `notification_id`, `icon`, `route`, `content_id`.
  factory NotificationModel.fromPush(PushNotificationData push) {
    final data = push.data ?? const <String, String>{};
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = (data['notification_id'] ?? '').trim();
    return NotificationModel(
      // If the backend omits notification_id, derive a stable id from the
      // notification content so that re-delivery (e.g. SDK pendingNotifications
      // drain after a Flutter engine restart) maps to the same record and
      // upsert stays idempotent. Avoids timestamp-based ids that differ on
      // each call and would create visual duplicates in the list.
      id: id.isEmpty ? contentFallbackId(push, data) : id,
      title: push.title ?? '',
      message: push.body ?? '',
      iconKey: data['icon'],
      imageUrl: push.imageUrl ?? data['image_url'],
      receivedAt: now,
      read: false,
      route: data['route'],
      contentId: data['content_id'],
    );
  }

  /// djb2 hash of notification content — stable across Dart process restarts
  /// unlike String.hashCode, which uses a random seed.
  ///
  /// Public so the iOS NSE can replicate the same algorithm. The NSE stores raw
  /// push data; when [notification_id] is absent from the backend, both sides
  /// must derive the same fallback [id] to keep [NotificationsRepository.upsert]
  /// idempotent across the foreground listener and the NSE queue drain.
  static String contentFallbackId(
      PushNotificationData push, Map<String, String> data) {
    return _djb2Hex(
      '${push.title ?? ''}|${push.body ?? ''}|${data['route'] ?? ''}|${data['content_id'] ?? ''}',
    );
  }

  static String _djb2Hex(String raw) {
    int h = 5381;
    for (final c in raw.codeUnits) {
      h = ((h << 5) + h + c) & 0xFFFFFFFF;
    }
    return 'auto_${h.toRadixString(16).padLeft(8, '0')}';
  }
}
