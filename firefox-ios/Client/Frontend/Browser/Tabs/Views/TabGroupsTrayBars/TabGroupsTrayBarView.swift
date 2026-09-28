// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

struct TabGroupsTrayTopBar: View {
    let viewModel: TabGroupsTrayBarViewModel
    let onAction: (TabGroupsTrayBarAction) -> Void

    var body: some View {
        ZStack {
            HStack {
                Spacer()

                Button {
                    onAction(.openMoreMenu)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(Color(uiColor: .label))
                        .frame(width: 40, height: 40)
                        .background(.regularMaterial, in: Circle())
                }
                .accessibilityLabel("More tab options")
                .accessibilityIdentifier("tabGroupsTray.more")
            }

            Button {
                onAction(.openDestinationPicker)
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(viewModel.isGroupSelected ? groupTint : Color(uiColor: .label))

                    Text(viewModel.destinationTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(uiColor: .label))

                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                }
                .padding(.horizontal, 14)
                .frame(height: 36)
                .background(.regularMaterial, in: Capsule())
            }
            .accessibilityIdentifier("tabGroupsTray.destination")
        }
        .padding(.horizontal, 20)
        .frame(height: 48)
    }

    private var groupTint: Color {
        Color(red: 0.96, green: 0.38, blue: 0.16)
    }
}

struct TabGroupsTrayBottomBar: View {
    let viewModel: TabGroupsTrayBarViewModel
    let onAction: (TabGroupsTrayBarAction) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button {
                onAction(.addTab)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 40, height: 40)
                    .background(.regularMaterial, in: Circle())
            }
            .accessibilityLabel("New tab")
            .accessibilityIdentifier("tabGroupsTray.addTab")

            Spacer(minLength: 0)

            HStack(spacing: 2) {
                panelButton(viewModel.privateTitle, panel: .privateTabs)
                panelButton(viewModel.tabsTitle, panel: .tabs)
                panelButton(viewModel.syncedTitle, panel: .syncedTabs)
            }
            .padding(3)
            .background(.regularMaterial, in: Capsule())

            Spacer(minLength: 0)

            Button {
                onAction(.done)
            } label: {
                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(uiColor: .systemBackground))
                    .frame(width: 40, height: 40)
                    .background(Color(uiColor: .label), in: Circle())
            }
            .accessibilityLabel(viewModel.doneAccessibilityLabel)
            .accessibilityIdentifier("tabGroupsTray.done")
        }
        .foregroundStyle(Color(uiColor: .label))
        .padding(.horizontal, 20)
        .frame(height: 56)
    }

    private func panelButton(_ title: String, panel: TabGroupsTrayBarViewModel.Panel) -> some View {
        Button {
            onAction(.selectPanel(panel))
        } label: {
            Text(title)
                .font(.system(size: 12, weight: panel == viewModel.selectedPanel ? .semibold : .medium))
                .lineLimit(1)
                .padding(.horizontal, 9)
                .frame(height: 32)
                .background {
                    if panel == viewModel.selectedPanel {
                        Capsule().fill(Color(uiColor: .secondarySystemGroupedBackground))
                    }
                }
        }
        .accessibilityIdentifier("tabGroupsTray.panel.\(panel)")
        .accessibilityAddTraits(panel == viewModel.selectedPanel ? .isSelected : [])
    }
}
