import Foundation
import ActivityKit
import Flutter

@available(iOS 16.1, *)
class LiveActivityManager {
    static let shared = LiveActivityManager()
    
    private var currentActivity: Activity<LiveActivityWidgetAttributes>?
    
    func register(with controller: FlutterViewController) {
        let channel = FlutterMethodChannel(name: "com.aitodo.liveActivity", binaryMessenger: controller.binaryMessenger)
        
        channel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            
            switch call.method {
            case "startActivity":
                if let args = call.arguments as? [String: Any],
                   let taskName = args["taskName"] as? String,
                   let deadline = args["deadline"] as? Int {
                    self.startActivity(taskName: taskName, deadline: deadline)
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                }
                
            case "stopActivity":
                self.stopActivity()
                result(nil)
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
    
    private func startActivity(taskName: String, deadline: Int) {
        stopActivity() // Stop existing first
        
        let attributes = LiveActivityWidgetAttributes(taskName: taskName, deadline: deadline)
        let contentState = LiveActivityWidgetAttributes.ContentState(status: "ACTIVE")
        
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
    
    private func stopActivity() {
        Task {
            for activity in Activity<LiveActivityWidgetAttributes>.activities {
                await activity.end(dismissalPolicy: .immediate)
            }
            self.currentActivity = nil
        }
    }
}
