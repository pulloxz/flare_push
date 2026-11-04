import Flutter
import UIKit
import UserNotifications

public class FlarePushPlugin: NSObject, FlutterPlugin, UNUserNotificationCenterDelegate {
  private let channel: FlutterMethodChannel
  private var waiting: [FlutterResult] = []

  init(channel: FlutterMethodChannel) {
    self.channel = channel
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flare_push", binaryMessenger: registrar.messenger())
    let instance = FlarePushPlugin(channel: channel)
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.addApplicationDelegate(instance)
    if UNUserNotificationCenter.current().delegate == nil {
      UNUserNotificationCenter.current().delegate = instance
    }
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "getToken" else {
      result(FlutterMethodNotImplemented)
      return
    }
    NSLog("FLAREPUSH getToken called")
    waiting.append(result)
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, err in
      NSLog("FLAREPUSH auth granted=\(granted) err=\(String(describing: err))")
      DispatchQueue.main.async {
        UIApplication.shared.registerForRemoteNotifications()
      }
    }
  }

  public func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    NSLog("FLAREPUSH didRegister")
    let token = deviceToken.map { String(format: "%02x", $0) }.joined()
    if waiting.isEmpty {
      channel.invokeMethod("onToken", arguments: token)
      return
    }
    let results = waiting
    waiting = []
    results.forEach { $0(token) }
  }

  public func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    NSLog("FLAREPUSH didFail \(error)")
    let results = waiting
    waiting = []
    results.forEach {
      $0(FlutterError(code: "apns", message: error.localizedDescription, details: nil))
    }
  }

  public func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .list, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }
}
