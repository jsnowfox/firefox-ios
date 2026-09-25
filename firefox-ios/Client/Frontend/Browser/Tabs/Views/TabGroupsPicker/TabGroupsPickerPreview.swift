// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

private struct TabGroupsPickerPreviewHost: View {
    @State private var selectedDestinationID: String
    let selectedTabCount: Int

    init(selectedDestinationID: String = "mobile", selectedTabCount: Int = 3) {
        _selectedDestinationID = State(initialValue: selectedDestinationID)
        self.selectedTabCount = selectedTabCount
    }

    var body: some View {
        TabGroupsPickerView(
            viewModel: TabGroupsPickerViewModel(
                title: "Tab Groups",
                editTitle: "Edit",
                doneAccessibilityLabel: "Done",
                destinations: [
                    .init(id: "mobile", title: "Mobile", kind: .device),
                    .init(id: "homes", title: "Homes", kind: .group),
                    .init(id: "pet-stuff", title: "Pet Stuff", kind: .group),
                    .init(id: "project-ideas", title: "Project Ideas", kind: .group)
                ],
                privateDestination: .init(id: "private", title: "Private", kind: .privateTabs),
                selectedDestinationID: selectedDestinationID,
                createEmptyGroupTitle: "New Empty Tab Group",
                createWithSelectedTabsTitle: selectedTabCount > 0
                    ? "New Tab Group with \(selectedTabCount) Tabs"
                    : nil
            ),
            onAction: { action in
                if case .selectDestination(let id) = action {
                    selectedDestinationID = id
                }
            }
        )
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

#Preview("Mobile selected") {
    TabGroupsPickerPreviewHost()
}

#Preview("Group selected") {
    TabGroupsPickerPreviewHost(selectedDestinationID: "homes")
}

#Preview("No selected tabs") {
    TabGroupsPickerPreviewHost(selectedTabCount: 0)
}

#Preview("Dark") {
    TabGroupsPickerPreviewHost()
        .preferredColorScheme(.dark)
}
