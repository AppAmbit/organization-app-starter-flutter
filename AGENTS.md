# AGENTS.md

Flutter + Riverpod + AppAmbit CMS. 5-tab shell (Home, Categories, Resources, Notifications, About). Only Home + Notifications implemented.

## Commands

| Action | Command |
|--------|---------|
| Deps | `flutter pub get` |
| Run | `flutter run` |
| Analyze | `flutter analyze` |
| Test | `flutter test` (no tests exist yet) |
| Single test | `flutter test test/foo_test.dart` |
| Build Android | `flutter build apk` |
| Build iOS | `flutter build ios` |
| Rename bundle | `dart run change_app_package_name:main com.example.new` |

## Architecture

- **Bootstrap order** (`lib/main.dart`): `dotenv.load()` → `AppAmbitSdk.start(appKey:)` → `PushNotificationsSdk.start()` → background handler → `runApp(ProviderScope(...))`. Do not reorder.
- **Local SDK deps** (path): `appambit_sdk_flutter` + `appambit_sdk_push_notifications` from sibling repos (`../../appambit-sdk-flutter/`).
- **Env**: `.env` (gitignored) with `APPAMBIT_APPKEY_IOS`/`APPAMBIT_APPKEY_ANDROID`. Example at `.env.example`.
- **Content types** in `lib/core/constants.dart`: `feed_carousel` → `FeedCollection`, `content_details` → `ContentDetail`. AppConstants holds CMS slugs (for reference only).
- **CMS data** arrives as `Map<Object?, Object?>` — all `fromMap` factories use `Map<String, dynamic>.from(e)` cast.
- **Feed sections** sorted by `displayOrder` in `home_feed_sections_providers.dart`.
- **`FeedCollection.items`** getter: `isCollection=true` → child items; `isCollection=false` → wraps self as single `CollectionItem`.
- **Image resolution** (same pattern in `FeedCollection` + `CollectionItem`): `image_url` (full URL from backend) > `image` (raw filename).
- **Content ID resolution** (same pattern in both models): `content` nested `Map` > `content` raw `String` > `content_detail` nested `Map` > `content_detail` raw `String`.
- **Card types** (defined in `HomeFeedModuleSection`): `featured` → PageView+dots, `large`/`small` → horizontal list, single-item gets centered full-width.
- **Content max-width**: 1100 tablet-landscape / 820 tablet-portrait / ∞ phone. `ContentDetailScreen` body constrained to 700.
- **Bottom bar** driven by `bottomBarVisibleProvider`; hide/show on scroll via `UserScrollNotification`.
- **Connectivity** (`connectivityProvider`): one-shot fetch at launch, not a live stream. `connectivity_plus`.
- **SnackBarAppWidget**: single notification surface via `rootNavigatorKey`. Canonical in `lib/shared/widgets/`; `lib/core/widgets/` is a barrel re-export.

## Push Notifications

Three delivery paths, all idempotent via upsert-by-id in `NotificationsRepository`:
1. **Foreground** — `setForegroundListener` → `notificationsProvider.notifier.add()`
2. **Android background** — `_backgroundNotificationHandler` writes to SharedPreferences; main isolate calls `reload()` on `AppLifecycleState.resumed`
3. **iOS background (NSE)** — `OrganizationAppServerNse` writes to App Group `UserDefaults` at key `flutter.notifications.items.v1`; `IosNotificationBridge.drainPending()` reads+clears via `MethodChannel('org.app/notifications_ios')` on launch/resume

Other push facts:
- App Group: `group.com.AppAmbit.TestAppSwift`
- `notificationsProvider` (`AsyncNotifierProvider`) is the SSOT for notification list
- `unreadCountProvider` derives badge count; `pushEnabledProvider` wraps SDK permission/state
- `NotificationsRepository` persists under `notifications.items.v1`, cap 100, newest-first
- Push payload keys: `notification_id` (dedup, fallback to epoch ms), `icon` (resolved via `notification_icons.dart`), `route` + `content_id` (navigation)
- 2-second delay before `setNotificationsEnabled(true)` gives APNs time for device token

## Editing Rules

- Keep feature logic in feature folders (`lib/features/`); avoid placing in `main.dart`.
- Do not remove debug/error logging around CMS parsing/providers without replacement diagnostics.
- Prefer existing URL resolution/fallback in model/widget code over adding parallel image logic.
- Reuse existing deps before adding new packages. Check `pubspec.yaml` first.
- Keep changes small and scoped; no broad refactors unless asked.
- `rootNavigatorKey` in `main.dart` must not be removed or reassigned — `SnackBarAppWidget` depends on it.

## Code Quality Rules

These rules apply to ALL contributors and AI agents. Violating them requires explicit justification.

### Colors — AppColors only
- **Never** write `Color(0xFF...)` outside `lib/core/styles/app_colors.dart`.
- All colors must be defined as `static const` in `AppColors` and referenced as `AppColors.xxx` everywhere.
- To add a new color: add it to `AppColors` first, then use it.
- Semantic names only (e.g. `AppColors.carouselDotActive`, not `AppColors.indigo600`).

### Layout Constants — AppLayout only
- Breakpoints and max-widths live in `AppLayout` (in `lib/core/constants.dart`).
  - `AppLayout.tabletBreakpoint` = 600.0
  - `AppLayout.maxWidthTabletLandscape` = 1100.0
  - `AppLayout.maxWidthTabletPortrait` = 820.0
  - `AppLayout.contentMaxWidth` = 700.0
- **Never** hardcode `600`, `1100`, `820`, `700` inline. Use the constants.

### Route Strings — NotificationRoute only
- `'content_detail'` route string must come from `NotificationRoute.contentDetail` (in `lib/core/constants.dart`).
- No bare string literals for route names.

### Package Isolation — Facade wrappers
Every third-party package (except `flutter`, `flutter_riverpod`, and the AppAmbit SDKs) must be wrapped:

| Package | Wrapper location |
|---|---|
| `cached_network_image` | `lib/shared/widgets/app_network_image.dart` → `AppNetworkImage` |
| `url_launcher` | `lib/shared/services/url_launcher_service.dart` → `UrlLauncherService` |
| `shared_preferences` | `lib/shared/services/local_storage_service.dart` → `LocalStorageService` |
| `connectivity_plus` | `lib/shared/services/connectivity_service.dart` → `ConnectivityService` |
| `video_player` + `chewie` | `lib/shared/widgets/app_video_player.dart` → `AppVideoPlayer` |
| `google_fonts` | `lib/core/styles/app_theme.dart` → `AppTheme` |
| `flutter_dotenv` | `lib/core/config/app_config.dart` → `AppConfig` |
| `flutter_widget_from_html_core` | use inline only inside dedicated widget, not spread across screens |

Rule: feature files (`lib/features/**`) must NOT `import 'package:cached_network_image/...'`, `import 'package:url_launcher/...'`, `import 'package:shared_preferences/...'`, or `import 'package:connectivity_plus/...'` directly. Use the wrappers.

### SOLID / KISS
- **SRP**: Providers and Notifiers must NOT call `SnackBarAppWidget` or `Navigator` directly. Emit state; let widgets react via `ref.listen`.
- **SRP**: `main.dart` is the entry point only. Shell, tab bar, and providers belong in `lib/app/`.
- **OCP**: New card types → add to the builder map, don't modify `_buildCarousel` switch.
- **KISS**: No IIFEs (`() { ... }()`) inside widget `build()`. Extract to named methods or widgets.
- **KISS**: Use `AnimatedScale` for simple scale animations, not `Matrix4.diagonal3Values`.

### Shared Widgets
- `CardImage` (`lib/features/home/widgets/card_image.dart`) is the single image renderer for cards. Do not duplicate `CachedNetworkImage` + fallback logic in individual card widgets.
- `ImagePlaceholder` (`lib/features/home/widgets/_image_placeholder.dart`) is the single placeholder. Do not inline placeholder containers.

### Analytics
- All `AppAmbitSdk.trackEvent` calls go through `AnalyticsService` (`lib/shared/services/analytics_service.dart`).
- Named methods only (`AnalyticsService.trackResourceOpened`, etc.), not raw `trackEvent` strings in feature code.

### Error Handling
- Never swallow exceptions with bare `catch (_) {}`. Always `debugPrint` the error and stack trace.
- Video init errors: log `$e\n$st`, then set error state.
- `Uri.tryParse` always (never `Uri.parse` for external URLs). Check result != null before use.
- Color hex from CMS: validate length (6 or 8 chars) before adding `0xFF000000` prefix.

## Sources of Truth (priority order)

`lib/main.dart` > config files > `CLAUDE.md` > docs. If they conflict, trust the running code.
