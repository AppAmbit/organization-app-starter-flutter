<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://assets.appambit.com/logo-dark.svg">
    <source media="(prefers-color-scheme: light)" srcset="https://assets.appambit.com/logo-light.svg">
    <img src="https://assets.appambit.com/logo-light.svg" alt="AppAmbit" width="280">
  </picture>
</p>

<h1 align="center">Organization App Starter - Flutter</h1>

<p align="center">
  A production-ready Flutter app powered by <a href="https://appambit.com">AppAmbit</a>.<br>
  Clone it, point it at your own AppAmbit organization, import a content set, and you have a working
  app: home feed, article screens, push notifications, analytics and theming already wired.
</p>

<p align="center">
  <a href="https://flutter.dev"><img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.41.1-02569B?logo=flutter&logoColor=white&labelColor=1a1a1a"></a>
  <a href="https://dart.dev"><img alt="Dart" src="https://img.shields.io/badge/Dart-3.11-0175C2?logo=dart&logoColor=white&labelColor=1a1a1a"></a>
  <a href="samples/"><img alt="CMS-driven" src="https://img.shields.io/badge/content-CMS--driven-F59220?labelColor=1a1a1a"></a>
  <a href="https://docs.appambit.com"><img alt="AppAmbit Docs" src="https://img.shields.io/badge/AppAmbit-docs-26A7DF?labelColor=1a1a1a"></a>
  <a href="https://discord.com/invite/nJyetYue2s"><img alt="Discord" src="https://img.shields.io/badge/Discord-join-5865F2?logo=discord&logoColor=white&labelColor=1a1a1a"></a>
</p>

---

## What this is

**The app has no hardcoded screens.** Every card, section and article page comes from the CMS.

- One codebase can runs as a
  - Blog
  - Cinema billboard
  - Nonprofit app
  - Training app.
  - Starter app.
- Changing content needs no rebuild and no developer.
- Five ready-made content sets are in [`samples/`](samples/) — import one and the app fills up.

<table>
  <tr>
    <td width="50%"><img alt="Home feed" src="samples/screenshots/fitness/feed%20-%201.png"></td>
    <td width="50%"><img alt="Detail screen" src="samples/screenshots/fitness/feed%20-%203.png"></td>
  </tr>
  <tr>
    <td align="center"><em>Home feed — hero carousel + genre rows</em></td>
    <td align="center"><em>Detail screen — image, rich text, CTA button</em></td>
  </tr>
</table>

Same build, different dataset. More captures in [`samples/screenshots/`](samples/screenshots/).

> There is also a [React Native version](https://github.com/AppAmbit/organization-app-starter-react-native)
> of this starter, built on the same CMS content model. When a data-shape or parsing quirk looks
> odd here, that repo is usually the reference for how it's handled — see the comment in
> [`home_feed_providers.dart`](lib/features/home/providers/home_feed_providers.dart).

---

## Quick start

Five steps, about 15 minutes.

**Before you start**, have the [Flutter environment setup](https://docs.flutter.dev/get-started/install)
done:

- Flutter 3.41.1 (see `.fvmrc`)
- Xcode (iOS) and/or Android Studio (Android)
- CocoaPods, for iOS (`sudo gem install cocoapods`) — `flutter run`/`flutter build ios` invoke `pod install` for you

### 1. Install

```sh
git clone https://github.com/AppAmbit/organization-app-starter-flutter.git
```

```sh
cd organization-app-starter-flutter
flutter pub get
```

### 2. Set your app keys

1. Create an app in the [AppAmbit dashboard](https://appambit.com) — **one per platform**.
2. Copy the env template:

   ```sh
   cp .env.example .env
   ```

3. Paste your keys:

   ```
   APPAMBIT_APPKEY_IOS=<your-ios-app-key>
   APPAMBIT_APPKEY_ANDROID=<your-android-app-key>
   ```

The keys are loaded by [`AppConfig.load()`](lib/core/config/app_config.dart) before
`AppAmbitSdk.start()` runs in [`main.dart`](lib/main.dart), and picked per platform. `.env` is
bundled as a Flutter asset — nothing to edit in code, but the app **will crash on startup** without
this file.

### 3. Import content

Without content the feed is empty. [`samples/`](samples/) has everything you need:

```
samples/schema/content-types.json    ← the 4 content types, import once
samples/datasets/movies.json         ← or blog · nonprofit · fitness · starter-demo
```

Two ways to load it:

| | What it is | Time |
| --- | --- | --- |
| ⚡ **[Automated](samples/AUTOMATED-SETUP.md)** | Connect the AppAmbit MCP server and paste one prompt. It creates the content types, every entry with its relations resolved, **and** your `.env` — steps 2 and 3 in one go. | ~5 min |
| ✋ **[Manual](samples/README.md#manual-import)** | Import through the dashboard yourself, step by step. | ~20 min |

> **Images are left empty on purpose.** Each dataset tells you the exact ratio and size every card
> slot wants — see [samples/README.md → Images](samples/README.md#images).

### 4. Create the auth table

This starter ships without a login step, so you can skip this for now. If you add login and register
on top of AppAmbit's managed database, run this once in the database linked to your app:

```sql
CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  created_at TEXT NOT NULL,
  token TEXT,
  expires_at TEXT
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email ON users (email);
```

There is no separate sessions table — the hashed session token and its expiry live on the user row,
30 days by default. See the
[React Native starter](../organization-app-starter-react-native/README.md) for a working
implementation of this schema.

### 5. Run

```sh
flutter run
```

The home feed shows your imported content on launch — the app opens straight into the feed, there is
no login step.

---

## How content drives the UI

Four CMS content types, one relation chain:

```
feed_carousel ──carousel──> carousel_items ──content_detail──┐
      │                                                      ├──> content_details ──> content_detail_items
      └──────────────────────content─────────────────────────┘
```

- **`feed_carousel`** — the home feed sections, parsed by
  [`FeedCollection.fromMap`](lib/features/home/models/feed_collection.dart). `card_type` (`featured` /
  `large` / `small`) plus `is_collection` decide whether a section renders as the hero carousel, a
  horizontal carousel, or a single full-width banner. `display_order` sorts them.
- **`carousel_items`** — the cards inside a section, parsed by
  [`CollectionItem.fromMap`](lib/features/home/models/collection_item.dart).
- **`content_details`** — an ordered list of blocks for one detail screen.
- **`content_detail_items`** — the blocks themselves: `text` (rich HTML), `image`, `video`, `button`.

Full renderer tables and the authoring rules are in [**samples/README.md**](samples/README.md#how-the-data-drives-the-ui).

---

## What's included

| | |
| --- | --- |
| **CMS-driven feed** | [`HomeScreen`](lib/features/home/screens/home_screen.dart) + [`homeFeedSectionsProvider`](lib/features/home/providers/home_feed_providers.dart) turn `feed_carousel` into featured / large / small sections |
| **Article screens** | [`ContentDetailScreen`](lib/features/home/screens/content_detail_screen.dart) resolves ordered blocks — rich text, images, video, CTA buttons |
| **Push notifications** | Foreground / opened / background listeners, plus an iOS Notification Service Extension + App Group so notifications that arrive while the app is killed are still captured — see [`AppShell`](lib/app/app_shell.dart) |
| **Analytics** | AppAmbit SDK analytics on content opens and notification opens ([`AnalyticsService`](lib/shared/services/analytics_service.dart)) |
| **Theming** | [`AppTheme`](lib/core/styles/app_theme.dart) / [`AppColors`](lib/core/styles/app_colors.dart), responsive to tablet vs. phone via [`AppLayout`](lib/core/constants.dart) breakpoints |
| **Navigation** | Animated bottom tab bar — Home, Categories, Resources, Notifications (unread badge), About |

> **Note:** the `Categories` and `Resources` tabs in [`AppShell`](lib/app/app_shell.dart) are
> intentionally empty placeholders. The tabs are wired up — the screens are yours to build.

---

## Make it yours

### Required to ship as your own app

- **App keys** — `.env` ([step 2](#2-set-your-app-keys)).
- **App name** — three places:
  - [`lib/core/constants.dart`](lib/core/constants.dart) → `AppConstants.appTitle`
  - `android/app/src/main/AndroidManifest.xml` → `android:label`
  - `ios/Runner/Info.plist` → `CFBundleDisplayName`
- **Bundle id / package** — currently `com.organizationappstarter` on Android:
  - `android/app/build.gradle.kts` → `namespace` and `applicationId`
  - In Xcode, the Bundle Identifier of **both** the `Runner` app and the
    `OrganizationAppServerNse` (Notification Service Extension) target — currently
    `com.AppAmbit.TestAppSwift`
  - Or use the bundled [`change_app_package_name`](https://pub.dev/packages/change_app_package_name)
    dev dependency: `dart run change_app_package_name:main com.yourcompany.yourapp`
- **Icons & splash**:
  - `android/app/src/main/res/mipmap-*/`
  - `ios/Runner/Assets.xcassets/`
- **Push credentials** — your own Firebase file and iOS certificates. See
  [Push notifications setup](#push-notifications-setup).
- **App Group id** — iOS only, and only if you keep killed-app notification capture. The id
  `group.com.AppAmbit.TestAppSwift` appears in **four** places and all four must match:
  - `ios/Runner/Runner.entitlements`
  - `ios/Runner/AppDelegate.swift`
  - `ios/OrganizationAppServerNse/OrganizationAppServerNse.entitlements`
  - `ios/OrganizationAppServerNse/NotificationService.swift`

### Optional

- **Org name, contact and links** — `OrgInfo.defaultInfo` in
  [`about_data.dart`](lib/features/about/models/about_data.dart)
- **Brand colors and type** — [`lib/core/styles/`](lib/core/styles/) → `app_colors.dart`,
  `app_theme.dart`
- **Tabs and screens** — [`lib/app/`](lib/app/), [`lib/features/`](lib/features/)

---

## Push notifications setup

The app runs fine without this. Do it when you want to actually deliver notifications.

> See full documentation about Push Notifications in [docs](https://docs.appambit.com/push-notifications/)

### Android

Firebase is the delivery channel, so Android needs a `google-services.json` from **your** Firebase
project. The repo ships a placeholder so you can see exactly what is expected and where it goes:

```
android/app/google-services-example.json   ← reference only, fake values, committed
android/app/google-services.json           ← put YOUR file here (same folder, this exact name), gitignored
```

Steps:

1. Open the [Firebase console](https://console.firebase.google.com/) → your project → **Project
   settings** → **Your apps** → add an Android app.
2. Use the same package name as `applicationId` in
   [`android/app/build.gradle.kts`](android/app/build.gradle.kts) — `com.organizationappstarter`
   unless you changed it. **A mismatch here is the usual reason push silently never arrives.**
3. Download `google-services.json` and drop it in `android/app/`, replacing the demo file.
4. Rebuild with `flutter run`. Gradle reads the file at build time, so a hot reload is not enough.

If the build complains, compare against `google-services-example.json`:

- `package_name` inside the file must match your `applicationId`.
- `project_id`, `mobilesdk_app_id` and `current_key` must be your real Firebase values, not the placeholders.

> The file is per-project, not a secret in the password sense — the Android API key is a client
> identifier restricted by package name. Still, it is yours: keep your real one out of forks and
> pull requests.

### iOS

1. Upload your APNs key or certificate in the AppAmbit dashboard.
2. In Xcode, enable **Push Notifications** and **Background Modes → Remote notifications** on the
   `Runner` target.
3. If you keep the killed-app capture feature, align the App Group id in all four files listed in
   [Make it yours](#make-it-yours).

---

## Project structure

```
lib/
├── main.dart             AppAmbit SDK + push notifications bootstrap, MaterialApp
├── app/                  AppShell (tab navigation), app-wide Riverpod providers
├── core/                 Env config, constants, theming, shared snackbar
├── features/
│   ├── home/              CMS feed, content detail, models/providers/screens/widgets
│   ├── notifications/      Foreground/background/opened delivery, notifications list
│   └── about/               Org info screen
└── shared/               Cross-feature services (analytics, connectivity, storage,
                            navigation, URL launching) and shared widgets
samples/                 Importable CMS schema + 5 content sets + screenshots
android/app/
└── google-services-example.json   Firebase placeholder — replace with your own
```

---

## Commands

| Command | Does |
| --- | --- |
| `flutter pub get` | Install dependencies |
| `flutter run` | Build and run on simulator/device |
| `flutter analyze` | Lint + typecheck (`flutter_lints` via `analysis_options.yaml`) |
| `flutter test` | Run tests (no `test/` directory exists yet) |
| `flutter build ios` / `apk` / `appbundle` | Build release artifacts |

---

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| **App crashes on startup** | `.env` is missing — copy `.env.example` and fill in your app keys. |
| **Feed is empty** | Content was not imported, or entries are `draft` — only `published` reaches the SDK. See [samples/README.md](samples/README.md). |
| **A section shows only one card** | `feed_carousel.carousel` is still a single relation. Switch it to a **many** relation in the dashboard. |
| **Cards render without images** | Expected on a fresh import. Upload art and set `image` / `banner_image` — [Images](samples/README.md#images). |
| **Push never arrives on Android** | The Firebase `package_name` does not match your `applicationId`. |
| **iOS build fails after pulling** | Re-run `flutter pub get`; if native dependencies changed, also `cd ios && pod install`. |
| **Anything else Flutter** | [Flutter common errors](https://docs.flutter.dev/testing/common-errors). |

---

## Learn more

- [**samples/README.md**](samples/README.md) — the data model, the datasets and the image slots
- [**samples/AUTOMATED-SETUP.md**](samples/AUTOMATED-SETUP.md) — configure the backend with one prompt
- [AppAmbit documentation](https://docs.appambit.com) — platform, CMS, SDKs
- [AppAmbit on GitHub](https://github.com/AppAmbit) — SDKs and open source projects
- [AppAmbit Discord](https://discord.com/invite/nJyetYue2s) — community and support
- [Flutter docs](https://docs.flutter.dev)
