import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var eventSink: FlutterEventSink?
  private let eventChannelName = "com.moprowallet/events"
  private var pendingLink: String?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Set up EventChannel for deep links
    if let controller = window?.rootViewController as? FlutterViewController {
      let eventChannel = FlutterEventChannel(
        name: eventChannelName,
        binaryMessenger: controller.binaryMessenger
      )
      eventChannel.setStreamHandler(self)
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Handle deep links when app is already running
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    handleDeepLink(url.absoluteString)
    return super.application(app, open: url, options: options)
  }
  
  // Handle universal links
  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
       let url = userActivity.webpageURL {
      handleDeepLink(url.absoluteString)
    }
    return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }
  
  private func handleDeepLink(_ link: String) {
    if let eventSink = eventSink {
      eventSink(link)
    } else {
      // Store the link for when Flutter is ready
      pendingLink = link
    }
  }
}

// MARK: - FlutterStreamHandler
extension AppDelegate: FlutterStreamHandler {
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events
    
    // Send any pending link that was received during cold start
    if let pendingLink = pendingLink {
      eventSink(pendingLink)
      self.pendingLink = nil
    }
    
    return nil
  }
  
  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.eventSink = nil
    return nil
  }
}
