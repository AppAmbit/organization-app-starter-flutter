## What type of PR is this? (check all applicable)

- [ ] 🛠️ Refactor
- [x] ✨ Feature
- [ ] 🐛 Bug Fix
- [ ] ⚡ Optimization
- [ ] 📚 Documentation Update

## Description

This PR adds the About screen, analytics tracking on notification opens, and image URL support in the notification model for the Flutter org app starter:

- **About screen** (`lib/features/about/`, new): displays organization info (name, description), contact section with pressable email and website rows, and a links section with external resources (docs, privacy policy, terms, Discord, GitHub). All links open via `url_launcher` and fire `AppAmbitSdk.trackEvent('Resource Opened', ...)` for analytics.
- **Notification analytics** (`lib/main.dart`): tracks `'Notification Opened'` event with title and body when user taps a push notification.
- **Notification image support** (`lib/features/notifications/`): adds `imageUrl` field to `NotificationModel`, persisted in SharedPreferences and populated from `PushNotificationData.imageUrl` with fallback to `data['image_url']` from push payload.

## Related Tickets & Documents

- [ID-1627](https://app.asana.com/1/1203353714760101/project/1204450899416459/task/1214393679339544)
- Closes #1627

## QA Instructions, Screenshots, Recordings

1. Run `flutter run` on iOS or Android.
2. **About screen**: tap the About tab — confirm org name, description, email, website, and all 5 external links display correctly and open the expected URLs.
3. **Notification analytics**: receive a push notification and tap it — confirm `'Notification Opened'` event is tracked via AppAmbit SDK.
4. Verify `flutter analyze` passes with no issues.

## Added/updated tests?

- [ ] ✅ Yes
- [x] ❌ No, and this is why: feature work focused on UI and analytics integration validated via manual QA and static analysis.
- [ ] 🤔 I need help with writing tests

## Are there any post deployment tasks we need to perform?

- [x] 📝 Yes (please add details)
- Copy `.env.example` to `.env` and fill in the correct `APPAMBIT_APPKEY_IOS` and `APPAMBIT_APPKEY_ANDROID` values for the target environment.
- [ ] ❌ No
- [ ] ❓ I don't know
