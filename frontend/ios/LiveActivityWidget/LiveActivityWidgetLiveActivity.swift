import ActivityKit
import WidgetKit
import SwiftUI

// LiveActivityWidgetAttributes is defined in LiveActivityAttributes.swift

struct ActivityTask: Codable, Hashable, Identifiable {
    var id: String
    var title: String
    var deadline: Int
}

struct LiveActivityWidgetLiveActivity: Widget {
    
    func getTasks(from json: String) -> [ActivityTask] {
        guard let data = json.data(using: .utf8) else { return [] }
        let decoder = JSONDecoder()
        return (try? decoder.decode([ActivityTask].self, from: data)) ?? []
    }

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivityWidgetAttributes.self) { context in
            // Lock screen/banner UI
            let tasks = getTasks(from: context.state.tasksJson)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Current Tasks")
                        .font(.caption)
                        .foregroundColor(Color(red: 0.56, green: 0.57, blue: 0.67))
                    Spacer()
                    Text(context.attributes.appName)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.42, green: 0.50, blue: 0.84))
                }
                
                if tasks.isEmpty {
                    Text("No active tasks")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else {
                    ForEach(tasks.prefix(3)) { task in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(Color(red: 0.29, green: 0.31, blue: 0.43))
                                .lineLimit(1)
                            
                            HStack {
                                Image(systemName: "timer")
                                    .font(.caption2)
                                    .foregroundColor(Color(red: 0.42, green: 0.50, blue: 0.84))
                                Text(timerInterval: Date()...Date(timeIntervalSince1970: TimeInterval(task.deadline)), countsDown: true)
                                    .font(.system(.caption, design: .monospaced))
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(red: 0.29, green: 0.31, blue: 0.43))
                            }
                        }
                        if task.id != tasks.last?.id {
                            Divider()
                        }
                    }
                }
            }
            .padding()
            .activityBackgroundTint(Color(red: 0.91, green: 0.92, blue: 0.94))
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            let tasks = getTasks(from: context.state.tasksJson)
            let firstTask = tasks.first
            
            return DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading) {
                        Label {
                            Text("\(tasks.count) Tasks")
                        } icon: {
                            Image(systemName: "checklist")
                        }
                        .font(.caption)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let task = firstTask {
                        Text(timerInterval: Date()...Date(timeIntervalSince1970: TimeInterval(task.deadline)), countsDown: true)
                            .font(.caption)
                            .monospacedDigit()
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if let task = firstTask {
                        Text(task.title)
                            .font(.headline)
                            .lineLimit(1)
                        if tasks.count > 1 {
                             Text("+ \(tasks.count - 1) more")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("No active tasks")
                    }
                }
            } compactLeading: {
                Image(systemName: "checklist")
                    .foregroundColor(Color(red: 0.42, green: 0.50, blue: 0.84))
            } compactTrailing: {
                if let task = firstTask {
                    Text(timerInterval: Date()...Date(timeIntervalSince1970: TimeInterval(task.deadline)), countsDown: true)
                        .monospacedDigit()
                        .font(.caption2)
                        .foregroundColor(Color(red: 0.42, green: 0.50, blue: 0.84))
                }
            } minimal: {
                Image(systemName: "timer")
                    .foregroundColor(Color(red: 0.42, green: 0.50, blue: 0.84))
            }
            .widgetURL(URL(string: "aitodo://home"))
            .keylineTint(Color(red: 0.42, green: 0.50, blue: 0.84))
        }
    }
}

extension LiveActivityWidgetAttributes {
    fileprivate static var preview: LiveActivityWidgetAttributes {
        LiveActivityWidgetAttributes(appName: "Obeyne")
    }
}

extension LiveActivityWidgetAttributes.ContentState {
    fileprivate static var active: LiveActivityWidgetAttributes.ContentState {
        LiveActivityWidgetAttributes.ContentState(tasksJson: "[]")
     }
}

#Preview("Notification", as: .content, using: LiveActivityWidgetAttributes.preview) {
   LiveActivityWidgetLiveActivity()
} contentStates: {
    LiveActivityWidgetAttributes.ContentState.active
}
