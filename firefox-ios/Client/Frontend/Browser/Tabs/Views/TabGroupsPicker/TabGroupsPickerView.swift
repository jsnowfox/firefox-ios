// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

struct TabGroupsPickerView: View {
    private enum UX {
        static let width: CGFloat = 377
        static let sheetRadius: CGFloat = 38
        static let cardRadius: CGFloat = 26
        static let horizontalPadding: CGFloat = 16
        static let rowHorizontalPadding: CGFloat = 24
        static let sectionSpacing: CGFloat = 20
        static let rowHeight: CGFloat = 52
        static let iconWidth: CGFloat = 22
    }

    let viewModel: TabGroupsPickerViewModel
    let onAction: (TabGroupsPickerAction) -> Void

    var body: some View {
        VStack(spacing: UX.sectionSpacing) {
            header
            destinationCard
            destinationRow(viewModel.privateDestination)
                .background(cardBackground, in: Capsule())
            creationCard
        }
        .padding(.horizontal, UX.horizontalPadding)
        .padding(.top, 16)
        .padding(.bottom, 24)
        .frame(maxWidth: UX.width)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: UX.sheetRadius))
        .shadow(color: .black.opacity(0.18), radius: 35, y: 15)
    }

    private var header: some View {
        ZStack {
            HStack {
                Button(viewModel.editTitle) {
                    onAction(.edit)
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(primaryText)
                .padding(.horizontal, 16)
                .frame(height: 44)
                .background(cardBackground.opacity(0.85), in: Capsule())
                .accessibilityIdentifier("tabGroupsPicker.edit")

                Spacer()

                Button {
                    onAction(.done)
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color(uiColor: .systemBackground))
                        .frame(width: 44, height: 44)
                        .background(primaryText, in: Circle())
                }
                .accessibilityLabel(viewModel.doneAccessibilityLabel)
                .accessibilityIdentifier("tabGroupsPicker.done")
            }

            Text(viewModel.title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(primaryText)
                .allowsHitTesting(false)
        }
        .frame(height: 44)
    }

    private var destinationCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModel.destinations.enumerated()), id: \.element.id) { index, destination in
                if index > 0 {
                    Divider()
                        .padding(.horizontal, UX.rowHorizontalPadding)
                }
                destinationRow(destination)
            }
        }
        .background(cardBackground, in: RoundedRectangle(cornerRadius: UX.cardRadius))
    }

    private func destinationRow(_ destination: TabGroupsPickerViewModel.Destination) -> some View {
        Button {
            onAction(.selectDestination(id: destination.id))
        } label: {
            HStack(spacing: 16) {
                Image(systemName: symbolName(for: destination.kind))
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: UX.iconWidth)

                Text(destination.title)
                    .font(.system(size: 17))

                Spacer(minLength: 8)

                if destination.id == viewModel.selectedDestinationID {
                    Image(systemName: "checkmark")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color(red: 0.43, green: 0.39, blue: 0.78))
                }
            }
            .foregroundStyle(primaryText)
            .padding(.horizontal, UX.rowHorizontalPadding)
            .frame(height: UX.rowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("tabGroupsPicker.destination.\(destination.id)")
        .accessibilityAddTraits(destination.id == viewModel.selectedDestinationID ? .isSelected : [])
    }

    private var creationCard: some View {
        VStack(spacing: 0) {
            creationRow(viewModel.createEmptyGroupTitle, action: .createEmptyGroup)
                .accessibilityIdentifier("tabGroupsPicker.createEmpty")

            if let title = viewModel.createWithSelectedTabsTitle {
                Divider()
                    .padding(.horizontal, UX.rowHorizontalPadding)
                creationRow(title, action: .createWithSelectedTabs)
                    .accessibilityIdentifier("tabGroupsPicker.createWithTabs")
            }
        }
        .background(cardBackground, in: RoundedRectangle(cornerRadius: UX.cardRadius))
    }

    private func creationRow(_ title: String, action: TabGroupsPickerAction) -> some View {
        Button {
            onAction(action)
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .regular))
                    .frame(width: UX.iconWidth)
                Text(title)
                    .font(.system(size: 17))
                Spacer(minLength: 0)
            }
            .foregroundStyle(primaryText)
            .padding(.horizontal, UX.rowHorizontalPadding)
            .frame(height: UX.rowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func symbolName(for kind: TabGroupsPickerViewModel.Destination.Kind) -> String {
        switch kind {
        case .device: "iphone"
        case .group: "square.grid.2x2"
        case .privateTabs: "theatermasks"
        }
    }

    private var cardBackground: Color {
        Color(uiColor: .secondarySystemGroupedBackground)
    }

    private var primaryText: Color {
        Color(uiColor: .label)
    }
}
