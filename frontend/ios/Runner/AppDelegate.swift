import UIKit
import Flutter
import ActivityKit

// Define attributes here to ensure availability in Runner target
struct LiveActivityWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var tasksJson: String
    }
    var appName: String
}

@available(iOS 16.1, *)
class LiveActivityManager {
    static let shared = LiveActivityManager()
    
    private var currentActivity: Activity<LiveActivityWidgetAttributes>?
    
    func register(with controller: FlutterViewController) {
        let channel = FlutterMethodChannel(name: "com.aitodo.liveActivity", binaryMessenger: controller.binaryMessenger)
        
        channel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            
            switch call.method {
            case "updateTasks":
                if let args = call.arguments as? [String: Any],
                   let tasksJson = args["tasksJson"] as? String {
                    self.updateTasks(tasksJson: tasksJson)
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                }
                
            case "stopActivity":
                self.stopAll()
                result(nil)
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
    
    private func updateTasks(tasksJson: String) {
        let contentState = LiveActivityWidgetAttributes.ContentState(tasksJson: tasksJson)
        
        // Check if we have an active activity
        if let activity = currentActivity ?? Activity<LiveActivityWidgetAttributes>.activities.first {
            self.currentActivity = activity
            Task {
                await activity.update(using: contentState)
                print("Live Activity updated")
            }
        } else {
            // Start new
            let attributes = LiveActivityWidgetAttributes(appName: "Obeyne")
            do {
                let activity = try Activity<LiveActivityWidgetAttributes>.request(
                    attributes: attributes,
                    contentState: contentState,
                    pushType: nil
                )
                self.currentActivity = activity
                print("Live Activity started: \(activity.id)")
            } catch {
                print("Error starting Live Activity: \(error.localizedDescription)")
            }
        }
    }
    
    private func stopAll() {
        Task {
            for activity in Activity<LiveActivityWidgetAttributes>.activities {
                await activity.end(dismissalPolicy: .immediate)
            }
            self.currentActivity = nil
        }
    }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    if #available(iOS 16.1, *) {
        if let controller = window?.rootViewController as? FlutterViewController {
            LiveActivityManager.shared.register(with: controller)
        }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
