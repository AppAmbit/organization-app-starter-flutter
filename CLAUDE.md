# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get          # install dependencies
flutter run              # run on connected device/emulator
flutter analyze          # lint (uses flutter_lints)
flutter test             # run all tests
flutter test test/foo_test.dart  # run a single test file
flutter build apk        # Android release build
flutter build ios        # iOS release build
dart run change_app_package_name:main com.example.new  # rename bundle id
```

## Architecture Overview

This is a **Flutter + Riverpod** app that renders a CMS-driven home feed using the **AppAmbit SDK** (`appambit_sdk_flutter`). The SDK is initialized in `main()` before `runApp`, and the entire widget tree is wrapped in `ProviderScope`.

Both SDK packages are local path dependencies from sibling repos:
- `appambit_sdk_flutter` → `../../appambit-sdk-flutter/appambit_sdk_flutter`
- `appambit_sdk_push_notifications` → `../../appambit-sdk-flutter/push/appambit_sdk_push_notifications`

### App Shell

`main.dart` hosts the 5-tab `AppShell` (Home, Categories, Resources, Notifications, About). Only Home and Notifications are implemented — the other three tabs render placeholder text. Bottom bar visibility is driven by `bottomBarVisibleProvider`, which hides/shows on scroll via `UserScrollNotification`.

A `GlobalKey<NavigatorState> rootNavigatorKey` is declared at the top of `main.dart` and passed to `MaterialApp`. `SnackBarAppWidget` uses this key to obtain a `BuildContext` without needing one passed in — do not remove or reassign it.

### CMS Integration

All live data comes from `AppAmbitCms.content<T>()` calls. The two active content types are defined in `lib/core/constants.dart`:

- `CmsContentType.feedCarousel` — fetches `FeedCollection` records (home feed sections)
- `CmsContentType.contentDetails` — fetches `ContentDetail` records (rich content pages)

`AppConstants` (same file) holds the CMS organization slug and raw collection names (`cmsHomeFeedCollection`, `cmsHomeFeedItemCollection`) used for reference — not passed to `AppAmbitCms` directly.

The SDK returns `Map<Object?, Object?>` from the platform channel, so all `fromMap` factories explicitly cast with `Map<String, dynamic>.from(e)`. In `FeedCollection.fromMap`, the child collection field accepts either key `'carousel'` or `'collection'` from the raw map.

### Home Feed Data Flow

```
homeFeedSectionsProvider (FutureProvider)
  → AppAmbitCms.feedCarousel → List<FeedCollection> (sorted by displayOrder)

sectionItemsProvider (Provider.family<FeedCollection>)
  → if isCollection=true  → FeedCollection.collection (child CollectionItems)
  → if isCollection=false → parent wrapped as single CollectionItem

contentDetailProvider (FutureProvider.family<String id>)
  → AppAmbitCms.contentDetails filtered by id → ContentDetail

connectivityProvider (FutureProvider<bool>)
  → one-shot check at launch via connectivity_plus; not a live stream
```

### Key Models

**`FeedCollection`** (`lib/features/home/models/feed_collection.dart`) — parent section record. Has `displayOrder`, `cardType` (featured/large/small), and `isCollection`. The `items` getter handles both collection and single-item modes.

**`CollectionItem`** — child card data. Image resolution: `image_url` (full URL from backend) takes priority over `image` (raw filename). The same `_resolveImageUrl` pattern exists in both models.

Content ID resolution (`_resolveContentId`) handles two shapes: `content` as a nested `Map` (expand) or as a raw `String` id, and the same for `content_detail`.

**`ContentDetail`** + `ContentDetailBlock` — rich content page with typed blocks: `text` (HTML rendered via `HtmlWidget`), `image`, `video` (played with `chewie`/`video_player`), `button` (launches URL).

### Home Feed Rendering

`HomeFeedModuleSection` receives a `FeedCollection` and switches on `cardType`:
- `featured` → `_FeaturedCarousel` (PageView + dot indicators)
- `large` → horizontal `ListView` or centered single card; single-item gets full-width treatment
- `small` → same pattern as large but smaller cards

Card tap → `ContentDetailScreen` pushed as `fullscreenDialog`.

### Layout Constraints

`AppShell` applies responsive max-width constraints: `1100` (tablet landscape) / `820` (tablet portrait) / `infinity` (phone). `ContentDetailScreen` constrains its body to `maxWidth: 700`. The letterbox background outside the content column uses `AppColors.gray100`.

### Push Notifications Architecture

Push uses `appambit_sdk_push_notifications`. SDK init order matters: `PushNotificationsSdk.start()` → `setNotificationsEnabled(true)` (after OS permission). A 2-second delay before `setNotificationsEnabled` gives APNs time to deliver the device token.

Three delivery paths, all idempotent via upsert-by-id in `NotificationsRepository`:

1. **Foreground** — `PushNotificationsSdk.setForegroundListener` calls `notificationsProvider.notifier.add()` directly.
2. **Android background** — a background isolate writes to SharedPreferences. The main isolate calls `notificationsProvider.notifier.reload()` on `AppLifecycleState.resumed`.
3. **iOS background (NSE)** — `OrganizationAppServerNse/NotificationService.swift` (extends `AppAmbitNotificationService`) writes records into an App Group `UserDefaults` queue under key `flutter.notifications.items.v1`. On launch/resume, `IosNotificationBridge.drainPending()` reads and clears this queue over `MethodChannel('org.app/notifications_ios')`, then merges results via `upsertAll`.

`NotificationsRepository` persists the list in SharedPreferences under `notifications.items.v1`, capped at 100 items, sorted newest-first. The App Group id is `group.com.AppAmbit.TestAppSwift`.

Push payload conventions from the backend:
- `notification_id` — dedup key (falls back to epoch ms)
- `icon` — icon key string, resolved to `IconData` at render via `notification_icons.dart`
- `route` — navigation hint (e.g., `"content_detail"`)
- `content_id` — entity to navigate to when route is `content_detail`

Opened push tap → `_handleOpened` marks the notification read, then either navigates to `ContentDetailScreen` (if route=`content_detail`) or switches to the Notifications tab.

### Notifications Screen State

`notificationsProvider` (`AsyncNotifierProvider`) is the single source of truth. `unreadCountProvider` derives the badge count. `pushEnabledProvider` wraps `PushNotificationsSdk.isNotificationsEnabled()` and handles the OS permission request flow inline.

### Theming

Font: Poppins via `google_fonts`. Accent color drives the color scheme seed (`AppColors.accent`). All color constants live in `lib/core/styles/app_colors.dart`. `SnackBarAppWidget` (canonical implementation in `lib/shared/widgets/snackbar_app_widget.dart`; `lib/core/widgets/snackbar_app_widget.dart` is just a re-export barrel) is the single notification surface — types defined in `lib/shared/domain/enums/data_general.dart`.

## Code Quality Rules

Enforce these on every edit. Full detail in `AGENTS.md § Code Quality Rules`.

- **Colors**: `Color(0xFF...)` only inside `lib/core/styles/app_colors.dart`. Use `AppColors.xxx` everywhere else.
- **Layout**: Magic numbers `600`, `1100`, `820`, `700` → use `AppLayout.*` from `lib/core/constants.dart`.
- **Routes**: `'content_detail'` string → `NotificationRoute.contentDetail` from `lib/core/constants.dart`.
- **Packages**: Feature files must not import `cached_network_image`, `url_launcher`, `shared_preferences`, or `connectivity_plus` directly. Use wrappers in `lib/shared/`.
- **SOLID/SRP**: Providers/Notifiers don't call `SnackBarAppWidget` or `Navigator`. Widgets react via `ref.listen`.
- **KISS**: No IIFEs in `build()`. Use `AnimatedScale` not `Matrix4.diagonal3Values`.
- **Images**: Use `CardImage` widget for card images. Use `AppNetworkImage` for all `CachedNetworkImage` usage.
- **Analytics**: Route through `AnalyticsService`, never call `AppAmbitSdk.trackEvent` directly in feature code.
- **Errors**: Never `catch (_) {}` silently. Log error + stack. Use `Uri.tryParse`, never `Uri.parse` for external URLs.
