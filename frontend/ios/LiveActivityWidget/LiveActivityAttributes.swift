import ActivityKit
import Foundation

struct LiveActivityWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var tasksJson: String // JSON array of tasks: [{"id":"...","title":"...","deadline":123}]
    }
    var appName: String
}
