//
//  NotificationService.swift
//  OrganizationAppServerNse
//
//  Created by Jesus Isaias Marquez Canales on 27/05/26.
//

import UserNotifications
import AppAmbitPushNotificationsExtension

class NotificationService: AppAmbitNotificationService {

    private static let appGroupId = "group.com.AppAmbit.TestAppSwift"
    private static let sharedPrefsItemsKey = "flutter.notifications.items.v1"
    private static let maxItems = 100

    /// Called by the base class after parsing the payload, before image download.
    /// The base class handles image download and attachment automatically.
    override func handlePayload(_ notification: AppAmbitNotification,
                                content: UNMutableNotificationContent) {
        saveToSharedPreferences(notification: notification, content: content)
    }

    override func serviceExtensionTimeWillExpire() {
        super.serviceExtensionTimeWillExpire()
    }

    // MARK: - Shared preferences

    private func saveToSharedPreferences(notification: AppAmbitNotification,
                                         content: UNMutableNotificationContent) {
        guard let defaults = UserDefaults(suiteName: Self.appGroupId) else {
            NSLog("[Push] NSE: App Group %@ unavailable.", Self.appGroupId)
            return
        }

        let data = notification.data
        let notificationId = (data["notification_id"] as? String)
            ?? Self.contentFallbackId(
                title: content.title,
                body: content.body ?? "",
                route: data["route"] as? String,
                contentId: data["content_id"] as? String)

        var record: [String: Any] = [
            "id": notificationId,
            "title": content.title,
            "message": content.body,
            "receivedAt": Int(Date().timeIntervalSince1970 * 1000),
            "read": false,
        ]
        if let icon = data["icon"] as? String { record["iconKey"] = icon }
        if let route = data["route"] as? String { record["route"] = route }
        if let contentId = data["content_id"] as? String { record["contentId"] = contentId }

        var serialized = defaults.stringArray(forKey: Self.sharedPrefsItemsKey) ?? []
        serialized.removeAll { entry in
            guard let entryData = entry.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: entryData) as? [String: Any]
            else { return false }
            return (json["id"] as? String) == notificationId
        }
        if let recordData = try? JSONSerialization.data(withJSONObject: record),
           let json = String(data: recordData, encoding: .utf8) {
            serialized.append(json)
        }
        if serialized.count > Self.maxItems {
            serialized = Array(serialized.suffix(Self.maxItems))
        }
        defaults.set(serialized, forKey: Self.sharedPrefsItemsKey)
    }

    // MARK: - Fallback ID (mirrors Dart's _contentFallbackId / contentFallbackId)

    /// djb2 hash of the notification content, producing the same `auto_xxxx`
    /// string that [NotificationModel.contentFallbackId] returns on the Dart
    /// side. Used when the backend omits `notification_id` so that the NSE
    /// and the foreground listener derive identical IDs, keeping upserts
    /// idempotent across both delivery paths.
    private static func contentFallbackId(
        title: String,
        body: String,
        route: String?,
        contentId: String?
    ) -> String {
        let raw = "\(title)|\(body)|\(route ?? "")|\(contentId ?? "")"
        var h = 5381
        for c in raw.utf8 {
            h = ((h << 5) &+ h &+ Int(c)) & 0xFFFFFFFF
        }
        return String(format: "auto_%08x", h)
    }
}

