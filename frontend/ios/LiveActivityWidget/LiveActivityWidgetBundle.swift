//
//  LiveActivityWidgetBundle.swift
//  LiveActivityWidget
//
//  Created by 橋之口祥吾 on 2025/11/27.
//

import WidgetKit
import SwiftUI

@main
struct LiveActivityWidgetBundle: WidgetBundle {
    var body: some Widget {
        LiveActivityWidget()
        LiveActivityWidgetControl()
        LiveActivityWidgetLiveActivity()
    }
}
