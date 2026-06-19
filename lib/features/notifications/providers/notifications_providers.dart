import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appambit_sdk_push_notifications/appambit_sdk_push_notifications.dart';

import 'package:organization_app_starter/features/notifications/data/ios_notification_bridge.dart';
import 'package:organization_app_starter/features/notifications/data/notifications_repository.dart';
import 'package:organization_app_starter/features/notifications/models/notification_model.dart';

final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) => NotificationsRepository());

/// Canonical, persisted notification list for the UI.
///
/// Coexistence model (see also the iOS NSE and Android background handler):
/// - Foreground pushes call [add] directly (instant UI + persistence).
/// - Android background pushes are written to SharedPreferences by the
///   background isolate; [reload] re-reads them on app resume.
/// - iOS background pushes are written by the NSE into the App Group queue;
///   [build]/[reload] drain that queue and merge it in.
///
/// All paths upsert by id in the repository, so overlapping delivery is
/// idempotent.
class NotificationsNotifier extends AsyncNotifier<List<NotificationModel>> {
  NotificationsRepository get _repo => ref.read(notificationsRepositoryProvider);

  @override
  Future<List<NotificationModel>> build() => _loadAndDrain();

  Future<List<NotificationModel>> _loadAndDrain() async {
    final drained = await IosNotificationBridge.drainPending();
    if (drained.isNotEmpty) return _repo.upsertAll(drained);
    return _repo.load();
  }

  Future<void> add(NotificationModel item) async {
    final current = state.asData?.value ?? [];
    final existing = current.where((e) => e.id == item.id).firstOrNull;
    if (existing != null) {
      item = item.copyWith(
        read: item.read || existing.read,
        receivedAt: existing.receivedAt,
      );
    }
    state = AsyncData(await _repo.upsert(item));
  }

  Future<void> markRead(String id) async {
    state = AsyncData(await _repo.markRead(id));
  }

  Future<void> markAllRead() async {
    state = AsyncData(await _repo.markAllRead());
  }

  /// Re-reads persisted state and drains any pending NSE items. Call on resume.
  ///
  /// Background notifications are NOT delivered via
  /// [PushNotificationsSdk.setForegroundListener] — that listener only fires for
  /// pushes received while the app is actively in the foreground. The NSE queue
  /// (iOS) and the background isolate (Android) are the only paths that capture
  /// background pushes, so we must drain them here.
  ///
  /// Duplication is prevented by [NotificationModel.contentFallbackId] which
  /// generates identical ids on both the NSE (Swift) and Dart sides, keeping
  /// [NotificationsRepository.upsert] idempotent even when the foreground
  /// listener and this drain process the same notification concurrently.
  Future<void> reload() async {
    state = AsyncData(await _loadAndDrain());
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<NotificationModel>>(
        NotificationsNotifier.new);

/// Live unread count — drives the bottom tab badge.
final unreadCountProvider = Provider<int>((ref) {
  final async = ref.watch(notificationsProvider);
  return async.maybeWhen(
    data: (items) => items.where((e) => !e.read).length,
    orElse: () => 0,
  );
});

// ---------------------------------------------------------------------------
// Push enabled state
// ---------------------------------------------------------------------------

class PushEnabledNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => PushNotificationsSdk.isNotificationsEnabled();

  Future<void> toggle(bool enabled) async {
    await PushNotificationsSdk.setNotificationsEnabled(enabled);
    state = AsyncData(enabled);
  }
}

final pushEnabledProvider =
    AsyncNotifierProvider<PushEnabledNotifier, bool>(PushEnabledNotifier.new);

// ---------------------------------------------------------------------------
// Settings modal visibility
// ---------------------------------------------------------------------------

class _SettingsVisibleNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void show() => state = true;
  void hide() => state = false;
}

final settingsVisibleProvider =
    NotifierProvider<_SettingsVisibleNotifier, bool>(
        _SettingsVisibleNotifier.new);
