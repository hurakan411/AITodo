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
            let mainTask = tasks.first
            
            ZStack {
                // Background
                Color(red: 0.91, green: 0.92, blue: 0.94)
                
                VStack(spacing: 12) {
                    HStack {
                        Text("CURRENT TASKS")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.2)
                            .foregroundColor(Color(red: 0.56, green: 0.57, blue: 0.67))
                        Spacer()
                        if !tasks.isEmpty {
                            Text("\(tasks.count)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(red: 0.56, green: 0.57, blue: 0.67))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color(red: 0.91, green: 0.92, blue: 0.94))
                                        .shadow(color: Color.white, radius: 1, x: -1, y: -1)
                                        .shadow(color: Color(red: 0.85, green: 0.85, blue: 0.90), radius: 1, x: 1, y: 1)
                                )
                        }
                    }
                    
                    if tasks.isEmpty {
                        Text("No active tasks")
                            .font(.headline)
                            .foregroundColor(Color(red: 0.56, green: 0.57, blue: 0.67))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Display up to 3 tasks uniformly
                        ForEach(tasks.prefix(3)) { task in
                            HStack {
                                Text(task.title)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Color(red: 0.29, green: 0.31, blue: 0.43))
                                    .lineLimit(1)
                                Spacer()
                                Text(timerInterval: Date()...Date(timeIntervalSince1970: TimeInterval(task.deadline)), countsDown: true)
                                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color(red: 0.42, green: 0.50, blue: 0.84))
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.91, green: 0.92, blue: 0.94))
                                    .shadow(color: Color.white, radius: 3, x: -3, y: -3)
                                    .shadow(color: Color(red: 0.82, green: 0.82, blue: 0.87), radius: 3, x: 3, y: 3)
                            )
                        }
                        
                        if tasks.count > 3 {
                            Text("+ \(tasks.count - 3) more")
                                .font(.caption)
                                .foregroundColor(Color(red: 0.56, green: 0.57, blue: 0.67))
                        }
                    }
                }
                .padding(16)
            }
            .activityBackgroundTint(Color(red: 0.91, green: 0.92, blue: 0.94))
            .activitySystemActionForegroundColor(Color(red: 0.18, green: 0.19, blue: 0.26))

        } dynamicIsland: { context in
            let tasks = getTasks(from: context.state.tasksJson)
            let firstTask = tasks.first
            
            return DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading) {
                        Label {
                            Text(firstTask?.title ?? "Task")
                                .lineLimit(1)
                                .foregroundColor(.white)
                        } icon: {
                            Image(systemName: "timer")
                                .foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.8))
                        }
                        .font(.caption)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let task = firstTask {
                        Text(timerInterval: Date()...Date(timeIntervalSince1970: TimeInterval(task.deadline)), countsDown: true)
                            .font(.title2)
                            .fontWeight(.bold)
                            .monospacedDigit()
                            .foregroundColor(.white)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if tasks.count > 1 {
                        HStack {
                            Text("+ \(tasks.count - 1) other tasks")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundColor(.white)
            } compactTrailing: {
                if let task = firstTask {
                    Text(timerInterval: Date()...Date(timeIntervalSince1970: TimeInterval(task.deadline)), countsDown: true)
                        .monospacedDigit()
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            } minimal: {
                Image(systemName: "timer")
                    .foregroundColor(.white)
            }
            .widgetURL(URL(string: "aitodo://home"))
            .keylineTint(Color(red: 0.56, green: 0.57, blue: 0.67))
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
