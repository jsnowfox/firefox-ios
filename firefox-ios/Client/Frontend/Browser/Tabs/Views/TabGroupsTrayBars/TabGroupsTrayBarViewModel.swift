// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

struct TabGroupsTrayBarViewModel: Equatable {
    enum Panel: Equatable {
        case privateTabs
        case tabs
        case syncedTabs
    }

    let destinationTitle: String
    let isGroupSelected: Bool
    let tabCount: Int
    let selectedPanel: Panel
    let privateTitle: String
    let syncedTitle: String
    let doneAccessibilityLabel: String

    var tabsTitle: String {
        "\(tabCount) \(tabCount == 1 ? "Tab" : "Tabs")"
    }
}

enum TabGroupsTrayBarAction: Equatable {
    case openDestinationPicker
    case openMoreMenu
    case addTab
    case selectPanel(TabGroupsTrayBarViewModel.Panel)
    case done
}
