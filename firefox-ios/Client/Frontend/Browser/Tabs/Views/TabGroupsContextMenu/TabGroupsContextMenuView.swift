// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

struct TabGroupsContextMenuView: View {
    let viewModel: TabGroupsContextMenuViewModel
    let onAction: (TabGroupsContextMenuAction) -> Void

    var body: some View {
        Menu {
            Button {
                onAction(.selectTabs)
            } label: {
                Label(viewModel.selectTabsTitle, systemImage: "checkmark.rectangle.stack")
            }
            .accessibilityIdentifier("tabGroupsContextMenu.selectTabs")

            Menu {
                Button {
                    onAction(.arrangeTabsByOriginalOrder)
                } label: {
                    Label("Original Order", systemImage: viewModel.sortsByTitle ? "line.3.horizontal" : "checkmark")
                }
                Button {
                    onAction(.arrangeTabsByTitle)
                } label: {
                    Label("Title", systemImage: viewModel.sortsByTitle ? "checkmark" : "textformat")
                }
            } label: {
                Label(viewModel.arrangeTabsTitle, systemImage: "square.grid.2x2")
            }
            .accessibilityIdentifier("tabGroupsContextMenu.arrangeTabs")

            if viewModel.showsGroupActions {
                Button {
                    onAction(.customizeGroup)
                } label: {
                    Label(viewModel.customizeGroupTitle, systemImage: "square.and.pencil")
                }
                .accessibilityIdentifier("tabGroupsContextMenu.customizeGroup")
            }

            Divider()

            Button(role: .destructive) {
                onAction(.closeTabs)
            } label: {
                Label(viewModel.closeTabsTitle, systemImage: "xmark.square")
            }
            .accessibilityIdentifier("tabGroupsContextMenu.closeTabs")

            if viewModel.showsGroupActions {
                Button(role: .destructive) {
                    onAction(.ungroup)
                } label: {
                    Label(viewModel.ungroupTitle, systemImage: "square.on.square.dashed")
                }
                .accessibilityIdentifier("tabGroupsContextMenu.ungroup")
            }

            Divider()

            Button {
                onAction(.tabSettings)
            } label: {
                Label(viewModel.tabSettingsTitle, systemImage: "gearshape")
            }
            .accessibilityIdentifier("tabGroupsContextMenu.tabSettings")
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(Color(uiColor: .label))
                .frame(width: 40, height: 40)
                .glassMenuLabel()
        }
        .accessibilityLabel("More tab options")
        .accessibilityIdentifier("tabGroupsTray.more")
    }
}

private extension View {
    @ViewBuilder
    func glassMenuLabel() -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(.regular.interactive(), in: Circle())
        } else {
            background(.regularMaterial, in: Circle())
        }
    }
}
