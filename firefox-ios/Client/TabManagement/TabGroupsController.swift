// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@MainActor
final class TabGroupsController {
    private(set) var state = TabGroupsWindowState() {
        didSet {
            if state != oldValue { onChange?(state) }
        }
    }

    var onChange: ((TabGroupsWindowState) -> Void)?

    @discardableResult
    func createGroup(name: String,
                     emoji: String = "🗂️",
                     color: TabGroupColor = .orange,
                     tabIDs: [TabUUID] = [],
                     normalTabIDs: [TabUUID]) -> UUID {
        let id = UUID()
        let validIDs = orderedUnique(tabIDs.filter { normalTabIDs.contains($0) })
        removeMembership(for: validIDs)
        state.groups.append(TabGroup(id: id,
                                     name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                     emoji: emoji,
                                     color: color,
                                     tabIDs: validIDs,
                                     lastSelectedTabID: validIDs.first))
        state.selectedGroupID = id
        return id
    }

    func renameGroup(id: UUID, name: String) {
        guard let group = state.groups.first(where: { $0.id == id }) else { return }
        updateGroup(id: id, name: name, emoji: group.emoji, color: group.color)
    }

    func updateGroup(id: UUID, name: String, emoji: String, color: TabGroupColor) {
        guard let index = state.groups.firstIndex(where: { $0.id == id }) else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmoji = emoji.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedEmoji.isEmpty else { return }
        var group = state.groups[index]
        group.name = trimmedName
        group.emoji = trimmedEmoji
        group.color = color
        state.groups[index] = group
    }

    func deleteGroup(id: UUID) {
        state.groups.removeAll { $0.id == id }
        if state.selectedGroupID == id { state.selectedGroupID = nil }
    }

    func moveGroups(fromOffsets offsets: IndexSet, toOffset destination: Int) {
        let indexes = offsets.filter { state.groups.indices.contains($0) }
        guard !indexes.isEmpty, (0...state.groups.count).contains(destination) else { return }
        let moved = indexes.map { state.groups[$0] }
        for index in indexes.reversed() { state.groups.remove(at: index) }
        let insertionIndex = destination - indexes.filter { $0 < destination }.count
        state.groups.insert(contentsOf: moved, at: insertionIndex)
    }

    func selectGroup(id: UUID?) {
        guard id == nil || state.groups.contains(where: { $0.id == id }) else { return }
        state.selectedGroupID = id
    }

    func assignTab(_ tabID: TabUUID, to groupID: UUID?, normalTabIDs: [TabUUID]) {
        guard normalTabIDs.contains(tabID) else { return }
        guard groupID == nil || state.groups.contains(where: { $0.id == groupID }) else { return }
        removeMembership(for: [tabID])
        if let groupID, let index = state.groups.firstIndex(where: { $0.id == groupID }) {
            state.groups[index].tabIDs.append(tabID)
            state.groups[index].lastSelectedTabID = tabID
        }
    }

    func removeTab(_ tabID: TabUUID) {
        removeMembership(for: [tabID])
        if state.lastSelectedUngroupedTabID == tabID { state.lastSelectedUngroupedTabID = nil }
    }

    func reconcile(normalTabIDs: [TabUUID]) {
        let validIDs = Set(normalTabIDs)
        var seen = Set<TabUUID>()
        for index in state.groups.indices {
            state.groups[index].tabIDs = state.groups[index].tabIDs.filter {
                validIDs.contains($0) && seen.insert($0).inserted
            }
            if let lastID = state.groups[index].lastSelectedTabID,
               !state.groups[index].tabIDs.contains(lastID) {
                state.groups[index].lastSelectedTabID = state.groups[index].tabIDs.first
            }
        }
        if let lastID = state.lastSelectedUngroupedTabID,
           !validIDs.contains(lastID) || seen.contains(lastID) {
            state.lastSelectedUngroupedTabID = nil
        }
    }

    func recordSelectedTab(_ tabID: TabUUID, normalTabIDs: [TabUUID]) {
        guard normalTabIDs.contains(tabID) else { return }
        if let index = state.groups.firstIndex(where: { $0.tabIDs.contains(tabID) }) {
            state.groups[index].lastSelectedTabID = tabID
        } else {
            state.lastSelectedUngroupedTabID = tabID
        }
    }

    func visibleTabIDs(normalTabIDs: [TabUUID]) -> [TabUUID] {
        guard let selectedID = state.selectedGroupID,
              let group = state.groups.first(where: { $0.id == selectedID }) else {
            let groupedIDs = Set(state.groups.flatMap(\.tabIDs))
            return normalTabIDs.filter { !groupedIDs.contains($0) }
        }
        let selectedIDs = Set(group.tabIDs)
        return normalTabIDs.filter { selectedIDs.contains($0) }
    }

    func preferredTabID(normalTabIDs: [TabUUID]) -> TabUUID? {
        let visibleIDs = visibleTabIDs(normalTabIDs: normalTabIDs)
        if let selectedID = state.selectedGroupID,
           let tabID = state.groups.first(where: { $0.id == selectedID })?.lastSelectedTabID,
           visibleIDs.contains(tabID) {
            return tabID
        }
        if state.selectedGroupID == nil,
           let tabID = state.lastSelectedUngroupedTabID,
           visibleIDs.contains(tabID) {
            return tabID
        }
        return visibleIDs.first
    }

    private func removeMembership(for tabIDs: [TabUUID]) {
        let removedIDs = Set(tabIDs)
        for index in state.groups.indices {
            state.groups[index].tabIDs.removeAll { removedIDs.contains($0) }
            if let lastID = state.groups[index].lastSelectedTabID,
               removedIDs.contains(lastID) {
                state.groups[index].lastSelectedTabID = state.groups[index].tabIDs.first
            }
        }
    }

    private func orderedUnique(_ tabIDs: [TabUUID]) -> [TabUUID] {
        var seen = Set<TabUUID>()
        return tabIDs.filter { seen.insert($0).inserted }
    }
}
