// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

struct TabGroupsToolbarButtonViewModel: Equatable {
    let isActiveGroup: Bool
    let groupEmoji: String?
    let isEnabled: Bool
    let accessibilityLabel: String
}

@MainActor
extension TabGroupsToolbarButtonViewModel {
    static func configure(_ action: ToolbarActionConfiguration,
                          for windowUUID: WindowUUID) -> ToolbarActionConfiguration {
        guard TabGroupsFeatureFlag.isEnabled,
              action.actionType == .tabs,
              action.badgeImageName == nil,
              TabGroupsSessionStore.controller(for: windowUUID).state.selectedGroupID != nil else { return action }
        var configured = action
        configured.iconName = "tabGroupsLarge"
        configured.templateModeForImage = false
        configured.numberOfTabs = nil
        configured.badgeImageName = nil
        configured.maskImageName = nil
        configured.isSelected = true
        configured.cacheId = "tabGroupsToolbar.button"
        configured.a11yLabel = "Tab Groups"
        return configured
    }
}
