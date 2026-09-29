// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import UIKit

struct TabGroupEditorView: View {
    private static let emojis = [
        "🗂️", "🏠", "💼", "📚", "🎮", "✈️",
        "🛍️", "🎵", "📰", "💡", "🍽️", "❤️",
        "🏃", "🎬", "💻", "🧠", "🌍", "⭐️"
    ]

    let isEditing: Bool
    let onCancel: () -> Void
    let onSave: (String, String, TabGroupColor) -> Void

    @State private var name: String
    @State private var emoji: String
    @State private var color: TabGroupColor

    init(name: String = "",
         emoji: String = "🗂️",
         color: TabGroupColor = .orange,
         isEditing: Bool = false,
         onCancel: @escaping () -> Void,
         onSave: @escaping (String, String, TabGroupColor) -> Void) {
        self.isEditing = isEditing
        self.onCancel = onCancel
        self.onSave = onSave
        _name = State(initialValue: name)
        _emoji = State(initialValue: emoji)
        _color = State(initialValue: color)
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Group name", text: $name)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .accessibilityIdentifier("tabGroupEditor.name")
                } header: {
                    Text("Name")
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(Self.emojis, id: \.self) { option in
                            Button {
                                emoji = option
                            } label: {
                                Text(option)
                                    .font(.system(size: 26))
                                    .frame(width: 44, height: 44)
                                    .background(emoji == option ? selectedColor.opacity(0.18) : .clear,
                                                in: Circle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(option) icon")
                            .accessibilityAddTraits(emoji == option ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                        ForEach(TabGroupColor.allCases, id: \.self) { option in
                            Button {
                                color = option
                            } label: {
                                Circle()
                                    .fill(option.swiftUIColor)
                                    .frame(width: 32, height: 32)
                                    .overlay {
                                        if color == option {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 44)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(option.rawValue.capitalized) color")
                            .accessibilityAddTraits(color == option ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(isEditing ? "Customize Group" : "New Tab Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Create") {
                        onSave(name.trimmingCharacters(in: .whitespacesAndNewlines), emoji, color)
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("tabGroupEditor.save")
                }
            }
        }
        .navigationViewStyle(.stack)
        .tint(selectedColor)
    }

    private var selectedColor: Color { color.swiftUIColor }
}

extension TabGroupColor {
    var swiftUIColor: Color {
        let values = components
        return Color(red: values.red, green: values.green, blue: values.blue)
    }

    var uiColor: UIColor {
        let values = components
        return UIColor(red: values.red, green: values.green, blue: values.blue, alpha: 1)
    }
}

#Preview("New group") {
    TabGroupEditorView(onCancel: {}, onSave: { _, _, _ in })
}

#Preview("Customize group") {
    TabGroupEditorView(name: "Houses", emoji: "🏠", color: .orange, isEditing: true,
                       onCancel: {}, onSave: { _, _, _ in })
}
