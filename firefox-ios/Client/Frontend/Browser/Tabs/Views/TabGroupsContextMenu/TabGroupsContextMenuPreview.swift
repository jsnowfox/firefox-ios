// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

private struct TabGroupsContextMenuPreviewHost: View {
    @State private var isPresented = true
    let showsGroupActions: Bool

    var body: some View {
        let barModel = TabGroupsTrayBarViewModel(
            destinationTitle: showsGroupActions ? "Houses" : "Mobile",
            isGroupSelected: showsGroupActions,
            tabCount: 1,
            selectedPanel: .tabs,
            privateTitle: "Private",
            syncedTitle: "Sync",
            doneAccessibilityLabel: "Done"
        )
        let menuModel = TabGroupsContextMenuViewModel(
            showsGroupActions: showsGroupActions,
            selectTabsTitle: "Select Tabs",
            arrangeTabsTitle: "Arrange Tabs By",
            customizeGroupTitle: "Customize Group Details",
            closeTabsTitle: "Close Tabs",
            ungroupTitle: "Ungroup",
            tabSettingsTitle: "Tab Settings"
        )

        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                TabGroupsTrayTopBar(viewModel: barModel) { action in
                    if action == .openMoreMenu {
                        isPresented.toggle()
                    }
                }

                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(red: 0.13, green: 0.04, blue: 0.28))
                    .frame(width: 165, height: 225)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                TabGroupsTrayBottomBar(viewModel: barModel) { _ in }
            }

            if isPresented {
                TabGroupsContextMenuView(viewModel: menuModel) { _ in
                    isPresented = false
                }
                .padding(.top, 53)
                .padding(.trailing, 20)
            }
        }
        .frame(width: 393, height: 700)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

#Preview("Selected group options") {
    TabGroupsContextMenuPreviewHost(showsGroupActions: true)
}

#Preview("Mobile options") {
    TabGroupsContextMenuPreviewHost(showsGroupActions: false)
}

#Preview("Dark") {
    TabGroupsContextMenuPreviewHost(showsGroupActions: true)
        .preferredColorScheme(.dark)
}
