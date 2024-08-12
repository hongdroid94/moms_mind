import UIKit
import Flutter
import BackgroundTasks

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if #available(iOS 13.0, *) {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.example.momHeart.dailyNotification", using: nil) { task in
            self.handleDailyNotification(task: task as! BGAppRefreshTask)
        }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  @available(iOS 13.0, *)
  func handleDailyNotification(task: BGAppRefreshTask) {
    scheduleNextDailyNotification()

    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 1

    queue.addOperation {
      // Call the Flutter method to show notification
      let controller : FlutterViewController = self.window?.rootViewController as! FlutterViewController
      let channel = FlutterMethodChannel(name: "com.example.momHeart/background", binaryMessenger: controller.binaryMessenger)
      channel.invokeMethod("showNotification", arguments: nil)
    }

    task.expirationHandler = {
      queue.cancelAllOperations()
    }

    let lastOperation = queue.operations.last
    lastOperation?.completionBlock = {
      task.setTaskCompleted(success: !(lastOperation?.isCancelled ?? false))
    }
  }

  @available(iOS 13.0, *)
  func scheduleNextDailyNotification() {
    let request = BGAppRefreshTaskRequest(identifier: "com.example.momHeart.dailyNotification")
    request.earliestBeginDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())

    do {
      try BGTaskScheduler.shared.submit(request)
    } catch {
      print("Could not schedule app refresh: \(error)")
    }
  }
}