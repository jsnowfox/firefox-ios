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
                        .tabGroupsGlass(in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("More tab options")
                .accessibilityIdentifier("tabGroupsTray.more")
            }

            Button {
                onAction(.openDestinationPicker)
            } label: {
                HStack(spacing: 7) {
                    if let emoji = viewModel.groupEmoji, viewModel.isGroupSelected {
                        Text(emoji)
                            .font(.system(size: 16))
                    } else {
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(uiColor: .label))
                    }

                    Text(viewModel.destinationTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(uiColor: .label))

                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color(uiColor: .label))
                }
                .padding(.horizontal, 14)
                .frame(height: 36)
                .tabGroupsGlass(in: Capsule(), tint: viewModel.isGroupSelected ? viewModel.groupColor : nil)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("tabGroupsTray.destination")
        }
        .padding(.horizontal, 20)
        .frame(height: 48)
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
                    .tabGroupsGlass(in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("New tab")
            .accessibilityIdentifier("tabGroupsTray.addTab")

            Spacer(minLength: 0)

            HStack(spacing: 2) {
                panelButton(viewModel.privateTitle, panel: .privateTabs)
                panelButton(viewModel.tabsTitle, panel: .tabs)
                panelButton(viewModel.syncedTitle, panel: .syncedTabs)
            }
            .padding(3)
            .tabGroupsGlass(in: Capsule())

            Spacer(minLength: 0)

            Button {
                onAction(.done)
            } label: {
                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(uiColor: .systemBackground))
                    .frame(width: 40, height: 40)
                    .tabGroupsDoneStyle()
            }
            .buttonStyle(.plain)
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
                .font(.system(size: 14, weight: panel == viewModel.selectedPanel ? .semibold : .medium))
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

private extension View {
    @ViewBuilder
    func tabGroupsGlass<S: Shape>(in shape: S, tint: Color? = nil) -> some View {
        if #available(iOS 26.0, *) {
            if let tint {
                glassEffect(.regular.tint(tint.opacity(0.18)).interactive(), in: shape)
            } else {
                glassEffect(.regular.interactive(), in: shape)
            }
        } else {
            background(.regularMaterial, in: shape)
                .background(tint?.opacity(0.18) ?? .clear, in: shape)
        }
    }

    @ViewBuilder
    func tabGroupsDoneStyle() -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(.regular.tint(.black).interactive(), in: Circle())
        } else {
            background(Color(uiColor: .label), in: Circle())
        }
    }
}
