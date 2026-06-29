import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  private var notificationsChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "NotificationsIosBridge") {
      let channel = FlutterMethodChannel(
        name: "org.app/notifications_ios",
        binaryMessenger: registrar.messenger()
      )
      channel.setMethodCallHandler { [weak self] call, result in
        self?.handle(call, result: result)
      }
      notificationsChannel = channel
    }
  }

  /// Returns and clears the notifications saved by the NSE into the App Group.
  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "drainPending":
      let appGroupId = "group.com.AppAmbit.TestAppSwift"
      let key = "flutter.notifications.items.v1"
      guard let defaults = UserDefaults(suiteName: appGroupId) else {
        result([Any]())
        return
      }
      let jsonStrings = defaults.stringArray(forKey: key) ?? [String]()
      defaults.removeObject(forKey: key)
      let maps: [Any] = jsonStrings.compactMap { json in
        guard let data = json.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return dict
      }
      result(maps)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
