// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

struct TabGroupsToolbarButtonView: View {
    let viewModel: TabGroupsToolbarButtonViewModel
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Group {
                if let emoji = viewModel.groupEmoji, viewModel.isActiveGroup {
                    Text(emoji)
                        .font(.system(size: 20))
                } else {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color(uiColor: .label))
                }
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.isEnabled)
        .opacity(viewModel.isEnabled ? 1 : 0.45)
        .accessibilityLabel(viewModel.accessibilityLabel)
        .accessibilityIdentifier("tabGroupsToolbar.button")
    }
}
