// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

struct TabGroupsContextMenuView: View {
    private enum UX {
        static let width: CGFloat = 232
        static let rowHeight: CGFloat = 42
        static let radius: CGFloat = 18
    }

    let viewModel: TabGroupsContextMenuViewModel
    let onAction: (TabGroupsContextMenuAction) -> Void

    var body: some View {
        VStack(spacing: 0) {
            menuRow(viewModel.selectTabsTitle,
                    symbol: "checkmark.rectangle.stack",
                    identifier: "selectTabs",
                    action: .selectTabs)
            menuRow(viewModel.arrangeTabsTitle,
                    symbol: "square.grid.2x2",
                    hasSubmenu: true,
                    identifier: "arrangeTabs",
                    action: .arrangeTabs)

            if viewModel.showsGroupActions {
                menuRow(viewModel.customizeGroupTitle,
                        symbol: "square.and.pencil",
                        identifier: "customizeGroup",
                        action: .customizeGroup)
            }

            Divider().padding(.horizontal, 12)

            menuRow(viewModel.closeTabsTitle,
                    symbol: "xmark.square",
                    hasSubmenu: true,
                    isDestructive: true,
                    identifier: "closeTabs",
                    action: .closeTabs)

            if viewModel.showsGroupActions {
                menuRow(viewModel.ungroupTitle,
                        symbol: "square.on.square.dashed",
                        isDestructive: true,
                        identifier: "ungroup",
                        action: .ungroup)
            }

            Divider().padding(.horizontal, 12)

            menuRow(viewModel.tabSettingsTitle,
                    symbol: "gearshape",
                    identifier: "tabSettings",
                    action: .tabSettings)
        }
        .padding(.vertical, 6)
        .frame(width: UX.width)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: UX.radius))
        .shadow(color: .black.opacity(0.2), radius: 22, y: 10)
        .accessibilityIdentifier("tabGroupsContextMenu")
    }

    private func menuRow(_ title: String,
                         symbol: String,
                         hasSubmenu: Bool = false,
                         isDestructive: Bool = false,
                         identifier: String,
                         action: TabGroupsContextMenuAction) -> some View {
        Button {
            onAction(action)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .regular))
                    .frame(width: 19)

                Text(title)
                    .font(.system(size: 15))
                    .lineLimit(1)

                Spacer(minLength: 4)

                if hasSubmenu {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                }
            }
            .foregroundStyle(isDestructive ? Color.red : Color(uiColor: .label))
            .padding(.horizontal, 14)
            .frame(height: UX.rowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("tabGroupsContextMenu.\(identifier)")
    }
}
