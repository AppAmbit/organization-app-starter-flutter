import 'package:flutter/foundation.dart';

import 'package:organization_app_starter/shared/services/local_storage_service.dart';
import 'package:organization_app_starter/features/notifications/models/notification_model.dart';

/// Persists the in-app notification list via [LocalStorageService].
///
/// Records stored as JSON string array under [_key], newest-first, capped at
/// [_maxItems]. All writes upsert by [NotificationModel.id] — idempotent across
/// foreground listener, Android background isolate, and iOS NSE delivery paths.
class NotificationsRepository {
  static const String _key = 'notifications.items.v1';
  static const int _maxItems = 100;

  Future<List<NotificationModel>> load() async {
    await LocalStorageService.reload();
    return _parse(await LocalStorageService.getStringList(_key));
  }

  /// Inserts or updates [item] by id, then persists. Returns the new list.
  Future<List<NotificationModel>> upsert(NotificationModel item) async {
    await LocalStorageService.reload();
    final items = _parse(await LocalStorageService.getStringList(_key));
    final idx = items.indexWhere((e) => e.id == item.id);
    if (idx >= 0) {
      items[idx] = item.copyWith(read: item.read || items[idx].read);
    } else {
      items.add(item);
    }
    return _persist(items);
  }

  /// Upserts many items in one pass (used when draining the iOS App Group queue).
  Future<List<NotificationModel>> upsertAll(
      List<NotificationModel> incoming) async {
    final items = _parse(await LocalStorageService.getStringList(_key));
    for (final item in incoming) {
      final idx = items.indexWhere((e) => e.id == item.id);
      if (idx >= 0) {
        items[idx] = item.copyWith(read: item.read || items[idx].read);
      } else {
        items.add(item);
      }
    }
    return _persist(items);
  }

  Future<List<NotificationModel>> markRead(String id) async {
    final items = _parse(await LocalStorageService.getStringList(_key));
    final idx = items.indexWhere((e) => e.id == id);
    if (idx >= 0) items[idx] = items[idx].copyWith(read: true);
    return _persist(items);
  }

  Future<List<NotificationModel>> markAllRead() async {
    final items =
        _parse(await LocalStorageService.getStringList(_key))
            .map((e) => e.copyWith(read: true))
            .toList();
    return _persist(items);
  }

  List<NotificationModel> _parse(List<String>? raw) {
    final items = <NotificationModel>[];
    for (final s in raw ?? const []) {
      try {
        items.add(NotificationModel.fromJson(s));
      } catch (e) {
        debugPrint('[NotificationsRepository] Skipping corrupt entry: $e');
      }
    }
    return items;
  }

  Future<List<NotificationModel>> _persist(List<NotificationModel> items) async {
    items.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    final capped =
        items.length > _maxItems ? items.sublist(0, _maxItems) : items;
    await LocalStorageService.setStringList(
        _key, capped.map((e) => e.toJson()).toList());
    return capped;
  }
}
