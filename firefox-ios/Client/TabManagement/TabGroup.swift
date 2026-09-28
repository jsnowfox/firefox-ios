// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct TabGroupColorComponents {
    let red: Double
    let green: Double
    let blue: Double
}

enum TabGroupColor: String, CaseIterable {
    case red, orange, yellow, green, teal, blue, purple, pink

    var components: TabGroupColorComponents {
        switch self {
        case .red: TabGroupColorComponents(red: 0.88, green: 0.28, blue: 0.28)
        case .orange: TabGroupColorComponents(red: 0.96, green: 0.38, blue: 0.16)
        case .yellow: TabGroupColorComponents(red: 0.75, green: 0.53, blue: 0.08)
        case .green: TabGroupColorComponents(red: 0.20, green: 0.62, blue: 0.32)
        case .teal: TabGroupColorComponents(red: 0.13, green: 0.62, blue: 0.62)
        case .blue: TabGroupColorComponents(red: 0.20, green: 0.44, blue: 0.90)
        case .purple: TabGroupColorComponents(red: 0.54, green: 0.37, blue: 0.84)
        case .pink: TabGroupColorComponents(red: 0.84, green: 0.32, blue: 0.59)
        }
    }
}

struct TabGroup: Equatable, Identifiable {
    let id: UUID
    var name: String
    var emoji = "🗂️"
    var color: TabGroupColor = .orange
    var tabIDs: [TabUUID]
    var lastSelectedTabID: TabUUID?
}

struct TabGroupsWindowState: Equatable {
    var groups = [TabGroup]()
    var selectedGroupID: UUID?
    var lastSelectedUngroupedTabID: TabUUID?
}
