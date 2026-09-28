// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

private struct TabGroupsToolbarButtonPreviewHost: View {
    @State private var isActiveGroup: Bool

    init(isActiveGroup: Bool) {
        _isActiveGroup = State(initialValue: isActiveGroup)
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Mozilla")
                    .font(.system(size: 23, weight: .bold))

                Text("Welcome\nto Mozilla")
                    .font(.system(size: 38, weight: .bold))

                Text("From trustworthy tech to policies that defend your digital rights, we put you first — always.")
                    .font(.system(size: 15))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .foregroundStyle(.white)
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 380, alignment: .top)
            .background(Color(red: 0.08, green: 0.09, blue: 0.11))

            Spacer()

            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                    Text("mozilla.org")
                        .font(.system(size: 13))
                    Spacer()
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13))
                }
                .foregroundStyle(Color(uiColor: .secondaryLabel))
                .padding(.horizontal, 16)
                .frame(height: 36)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: Capsule())

                HStack(spacing: 0) {
                    fixtureButton("chevron.left")
                    fixtureButton("chevron.right")
                    fixtureButton("plus")
                    fixtureButton("ellipsis")

                    TabGroupsToolbarButtonView(
                        viewModel: TabGroupsToolbarButtonViewModel(
                            isActiveGroup: isActiveGroup,
                            groupEmoji: isActiveGroup ? "🏠" : nil,
                            isEnabled: true,
                            accessibilityLabel: "Tab Groups"
                        ),
                        onTap: { isActiveGroup.toggle() }
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 14)
            .background(.regularMaterial)
        }
        .frame(width: 393, height: 700)
        .background(Color(uiColor: .systemBackground))
    }

    private func fixtureButton(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 17))
            .foregroundStyle(Color(uiColor: .label))
            .frame(maxWidth: .infinity)
            .frame(height: 44)
    }
}

#Preview("Active group") {
    TabGroupsToolbarButtonPreviewHost(isActiveGroup: true)
}

#Preview("No active group") {
    TabGroupsToolbarButtonPreviewHost(isActiveGroup: false)
}

#Preview("Dark") {
    TabGroupsToolbarButtonPreviewHost(isActiveGroup: true)
        .preferredColorScheme(.dark)
}
