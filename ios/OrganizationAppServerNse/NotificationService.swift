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
            ?? String(Int(Date().timeIntervalSince1970 * 1000))

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
}

