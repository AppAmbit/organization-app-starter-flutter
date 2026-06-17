import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_model.dart';

/// Persists the in-app notification list in SharedPreferences.
///
/// The list is the single UI source of truth. Records are stored as a JSON
/// string array under [_key], kept newest-first and capped at [_maxItems].
/// All writes upsert by [NotificationModel.id] so every delivery path
/// (foreground listener, Android background isolate, drained iOS NSE entries)
/// is idempotent — see the coexistence rules in the notifications providers.
///
/// Safe to use from the Android background isolate: each method re-reads the
/// store before writing, so it never clobbers entries written by the main
/// isolate.
class NotificationsRepository {
  static const String _key = 'notifications.items.v1';
  static const int _maxItems = 100;

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<List<NotificationModel>> load() async {
    final prefs = await _prefs;
    // Refresh the in-memory cache from disk so the main isolate sees writes
    // made by the Android background isolate while the app was backgrounded.
    await prefs.reload();
    return _read(prefs);
  }

  /// Inserts or updates [item] by id, then persists. Returns the new list.
  Future<List<NotificationModel>> upsert(NotificationModel item) async {
    final prefs = await _prefs;
    final items = _read(prefs);
    final idx = items.indexWhere((e) => e.id == item.id);
    if (idx >= 0) {
      // Preserve an already-read state if a duplicate arrives.
      items[idx] = item.copyWith(read: item.read || items[idx].read);
    } else {
      items.add(item);
    }
    return _write(prefs, items);
  }

  /// Upserts many items in one pass (used when draining the iOS App Group queue).
  Future<List<NotificationModel>> upsertAll(
      List<NotificationModel> incoming) async {
    final prefs = await _prefs;
    final items = _read(prefs);
    for (final item in incoming) {
      final idx = items.indexWhere((e) => e.id == item.id);
      if (idx >= 0) {
        items[idx] = item.copyWith(read: item.read || items[idx].read);
      } else {
        items.add(item);
      }
    }
    return _write(prefs, items);
  }

  Future<List<NotificationModel>> markRead(String id) async {
    final prefs = await _prefs;
    final items = _read(prefs);
    final idx = items.indexWhere((e) => e.id == id);
    if (idx >= 0) items[idx] = items[idx].copyWith(read: true);
    return _write(prefs, items);
  }

  Future<List<NotificationModel>> markAllRead() async {
    final prefs = await _prefs;
    final items = _read(prefs).map((e) => e.copyWith(read: true)).toList();
    return _write(prefs, items);
  }

  Future<List<NotificationModel>> delete(String id) async {
    final prefs = await _prefs;
    final items = _read(prefs)..removeWhere((e) => e.id == id);
    return _write(prefs, items);
  }

  Future<List<NotificationModel>> clear() async {
    final prefs = await _prefs;
    await prefs.remove(_key);
    return const [];
  }

  List<NotificationModel> _read(SharedPreferences prefs) {
    final raw = prefs.getStringList(_key) ?? const [];
    final items = <NotificationModel>[];
    for (final s in raw) {
      try {
        items.add(NotificationModel.fromJson(s));
      } catch (_) {
        // Skip corrupt entries rather than failing the whole load.
      }
    }
    return items;
  }

  Future<List<NotificationModel>> _write(
      SharedPreferences prefs, List<NotificationModel> items) async {
    items.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    final capped =
        items.length > _maxItems ? items.sublist(0, _maxItems) : items;
    await prefs.setStringList(_key, capped.map((e) => e.toJson()).toList());
    return capped;
  }
}
