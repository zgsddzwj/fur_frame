//
//  FurFrameWidgetsLiveActivity.swift
//  FurFrameWidgets
//
//  Created by Adward on 2026/3/14.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct FurFrameWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct FurFrameWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FurFrameWidgetsAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension FurFrameWidgetsAttributes {
    fileprivate static var preview: FurFrameWidgetsAttributes {
        FurFrameWidgetsAttributes(name: "World")
    }
}

extension FurFrameWidgetsAttributes.ContentState {
    fileprivate static var smiley: FurFrameWidgetsAttributes.ContentState {
        FurFrameWidgetsAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: FurFrameWidgetsAttributes.ContentState {
         FurFrameWidgetsAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: FurFrameWidgetsAttributes.preview) {
   FurFrameWidgetsLiveActivity()
} contentStates: {
    FurFrameWidgetsAttributes.ContentState.smiley
    FurFrameWidgetsAttributes.ContentState.starEyes
}
