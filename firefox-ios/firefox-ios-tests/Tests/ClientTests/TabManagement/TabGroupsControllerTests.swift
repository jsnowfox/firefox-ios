// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

@MainActor
final class TabGroupsControllerTests: XCTestCase {
    func testAssigningTabMovesItBetweenGroupsAndMobile() throws {
        let controller = TabGroupsController()
        let firstID = try XCTUnwrap(controller.createGroup(name: "First", tabIDs: ["a"], normalTabIDs: ["a", "b"]))
        let secondID = try XCTUnwrap(controller.createGroup(name: "Second", normalTabIDs: ["a", "b"]))

        controller.assignTab("a", to: secondID, normalTabIDs: ["a", "b"])

        XCTAssertEqual(controller.state.groups.first { $0.id == firstID }?.tabIDs, [])
        XCTAssertEqual(controller.visibleTabIDs(normalTabIDs: ["a", "b"]), ["a"])

        controller.assignTab("a", to: nil, normalTabIDs: ["a", "b"])
        controller.selectGroup(id: nil)

        XCTAssertEqual(controller.visibleTabIDs(normalTabIDs: ["a", "b"]), ["a", "b"])
    }

    func testDeleteGroupReturnsTabsToMobile() throws {
        let controller = TabGroupsController()
        let groupID = try XCTUnwrap(controller.createGroup(name: "Work", tabIDs: ["a"], normalTabIDs: ["a", "b"]))

        controller.deleteGroup(id: groupID)

        XCTAssertNil(controller.state.selectedGroupID)
        XCTAssertEqual(controller.visibleTabIDs(normalTabIDs: ["a", "b"]), ["a", "b"])
    }

    func testMovingSelectedTabsChangesMembershipAndDestinationOnce() throws {
        let controller = TabGroupsController()
        let firstID = try XCTUnwrap(controller.createGroup(name: "First", tabIDs: ["a", "b"], normalTabIDs: ["a", "b", "c"]))
        let secondID = try XCTUnwrap(controller.createGroup(name: "Second", normalTabIDs: ["a", "b", "c"]))
        controller.selectGroup(id: firstID)
        var changeCount = 0
        controller.onChange = { _ in changeCount += 1 }

        controller.moveTabs(["a", "b", "a", "invalid"], to: secondID, normalTabIDs: ["a", "b", "c"])

        XCTAssertEqual(changeCount, 1)
        XCTAssertEqual(controller.state.selectedGroupID, secondID)
        XCTAssertEqual(controller.state.groups.first { $0.id == firstID }?.tabIDs, [])
        XCTAssertEqual(controller.state.groups.first { $0.id == secondID }?.tabIDs, ["a", "b"])

        controller.moveTabs(["a"], to: nil, normalTabIDs: ["a", "b", "c"])

        XCTAssertNil(controller.state.selectedGroupID)
        XCTAssertEqual(controller.visibleTabIDs(normalTabIDs: ["a", "b", "c"]), ["a", "c"])
    }

    func testVisibleTabsStayWithinSelectedDestination() {
        let controller = TabGroupsController()
        let normalTabIDs = ["a", "b", "c", "d"]
        let groupID = controller.createGroup(name: "Work", tabIDs: ["b", "d"], normalTabIDs: normalTabIDs)

        XCTAssertEqual(controller.visibleTabIDs(normalTabIDs: normalTabIDs), ["b", "d"])

        controller.selectGroup(id: nil)

        XCTAssertEqual(controller.visibleTabIDs(normalTabIDs: normalTabIDs), ["a", "c"])

        controller.selectGroup(id: groupID)

        XCTAssertEqual(controller.visibleTabIDs(normalTabIDs: normalTabIDs), ["b", "d"])
    }

    func testReconcileRemovesClosedTabsAndExcludesPrivateTabs() throws {
        let controller = TabGroupsController()
        let groupID = try XCTUnwrap(controller.createGroup(name: "Work", tabIDs: ["a", "private"], normalTabIDs: ["a", "b"]))
        controller.assignTab("private", to: groupID, normalTabIDs: ["a", "b"])
        controller.reconcile(normalTabIDs: ["b"])

        XCTAssertEqual(controller.state.groups[0].tabIDs, [])
        XCTAssertEqual(controller.visibleTabIDs(normalTabIDs: ["b"]), [])
    }

    func testReorderingGroupsKeepsSelectedGroup() throws {
        let controller = TabGroupsController()
        let firstID = try XCTUnwrap(controller.createGroup(name: "First", normalTabIDs: []))
        controller.createGroup(name: "Second", normalTabIDs: [])
        controller.createGroup(name: "Third", normalTabIDs: [])
        controller.selectGroup(id: firstID)

        controller.moveGroups(fromOffsets: IndexSet(integer: 0), toOffset: 3)

        XCTAssertEqual(controller.state.groups.map(\.name), ["Second", "Third", "First"])
        XCTAssertEqual(controller.state.selectedGroupID, firstID)
    }

    func testCreatingGroupRejectsEmptyNameOrEmoji() {
        let controller = TabGroupsController()

        XCTAssertNil(controller.createGroup(name: "  \n  ", normalTabIDs: ["a"]))
        XCTAssertNil(controller.createGroup(name: "Valid", emoji: "  ", normalTabIDs: ["a"]))
        XCTAssertTrue(controller.state.groups.isEmpty)
    }

    func testCreatingAndUpdatingGroupAppearance() throws {
        let controller = TabGroupsController()
        let groupID = try XCTUnwrap(controller.createGroup(name: "Work", emoji: "💼", color: .blue, normalTabIDs: []))

        XCTAssertEqual(controller.state.groups[0].emoji, "💼")
        XCTAssertEqual(controller.state.groups[0].color, .blue)

        controller.updateGroup(id: groupID, name: " Personal ", emoji: "🏠", color: .green)

        XCTAssertEqual(controller.state.groups[0].name, "Personal")
        XCTAssertEqual(controller.state.groups[0].emoji, "🏠")
        XCTAssertEqual(controller.state.groups[0].color, .green)
    }

    func testToolbarUsesSelectedGroupEmoji() {
        let windowUUID = UUID()
        defer { TabGroupsSessionStore.removeController(for: windowUUID) }
        let controller = TabGroupsSessionStore.controller(for: windowUUID)
        let action = ToolbarActionConfiguration(actionType: .tabs,
                                                iconName: "tabCount",
                                                numberOfTabs: 1,
                                                isEnabled: true,
                                                a11yLabel: "Tabs",
                                                a11yId: "tabs")

        XCTAssertEqual(TabGroupsToolbarButtonViewModel.configure(action, for: windowUUID), action)

        controller.createGroup(name: "Work", emoji: "💼", tabIDs: ["a"], normalTabIDs: ["a"])
        let configured = TabGroupsToolbarButtonViewModel.configure(action, for: windowUUID)

        if TabGroupsFeatureFlag.isEnabled {
            XCTAssertEqual(configured.actionLabel, "💼")
            XCTAssertNil(configured.iconName)
            XCTAssertNil(configured.numberOfTabs)
            XCTAssertEqual(configured.a11yLabel, "Work Tab Group")
        } else {
            XCTAssertEqual(configured, action)
        }
    }

    func testToolbarCountsOnlyMobileTabs() {
        let windowUUID = UUID()
        defer { TabGroupsSessionStore.removeController(for: windowUUID) }
        let controller = TabGroupsSessionStore.controller(for: windowUUID)
        let action = ToolbarActionConfiguration(actionType: .tabs,
                                                iconName: "tabCount",
                                                numberOfTabs: 3,
                                                isEnabled: true,
                                                a11yLabel: "Tabs",
                                                a11yId: "tabs")
        controller.createGroup(name: "Work", tabIDs: ["a", "c"], normalTabIDs: ["a", "b", "c"])
        controller.selectGroup(id: nil)

        let configured = TabGroupsToolbarButtonViewModel.configure(action,
                                                                   for: windowUUID,
                                                                   normalTabIDs: ["a", "b", "c"])

        XCTAssertEqual(configured.numberOfTabs, TabGroupsFeatureFlag.isEnabled ? 1 : 3)
    }
    func testSwitchingDestinationsRestoresLastSelectedVisibleTab() throws {
        let controller = TabGroupsController()
        let normalIDs = ["a", "b", "c"]
        let groupID = try XCTUnwrap(controller.createGroup(name: "Work",
                                                           tabIDs: ["b", "c"],
                                                           normalTabIDs: normalIDs))
        controller.recordSelectedTab("c", normalTabIDs: normalIDs)
        controller.selectGroup(id: nil)
        controller.recordSelectedTab("a", normalTabIDs: normalIDs)

        XCTAssertEqual(controller.preferredTabID(normalTabIDs: normalIDs), "a")
        controller.selectGroup(id: groupID)
        XCTAssertEqual(controller.preferredTabID(normalTabIDs: normalIDs), "c")
    }

    func testNewNormalTabStaysInSelectedGroup() throws {
        let controller = TabGroupsController()
        let groupID = try XCTUnwrap(controller.createGroup(name: "Work", normalTabIDs: ["a"]))

        controller.assignTab("b", to: groupID, normalTabIDs: ["a", "b"])
        controller.recordSelectedTab("b", normalTabIDs: ["a", "b"])

        XCTAssertEqual(controller.visibleTabIDs(normalTabIDs: ["a", "b"]), ["b"])
        XCTAssertEqual(controller.preferredTabID(normalTabIDs: ["a", "b"]), "b")
    }
}

private final class InMemoryTabGroupsTabManager: MockTabManager {
    override func removeTabs(_ tabs: [Tab]) {
        let removedIDs = Set(tabs.map(\.tabUUID))
        self.tabs.removeAll { removedIDs.contains($0.tabUUID) }
        normalTabs.removeAll { removedIDs.contains($0.tabUUID) }
        for id in removedIDs { tabsByUUID.removeValue(forKey: id) }
    }

    override func addTab(_ request: URLRequest?,
                         afterTab: Tab?,
                         zombie: Bool,
                         isPrivate: Bool) -> Tab {
        let tab = super.addTab(request, afterTab: afterTab, zombie: zombie, isPrivate: isPrivate)
        tabs.append(tab)
        normalTabs.append(tab)
        tabsByUUID[tab.tabUUID] = tab
        return tab
    }
}

final class TabGroupsTabActionsTests: TabManagerTestsBase {
    @MainActor
    private func createInMemoryManager(tabs: [Tab]) -> InMemoryTabGroupsTabManager {
        let manager = InMemoryTabGroupsTabManager()
        manager.tabs = tabs
        manager.normalTabs = tabs
        manager.tabsByUUID = Dictionary(uniqueKeysWithValues: tabs.map { ($0.tabUUID, $0) })
        return manager
    }

    @MainActor
    func testClosingActiveGroupTabSelectsAnotherTabInThatGroup() throws {
        let tabs = generateTabs(count: 3)
        let tabManager = createInMemoryManager(tabs: tabs)
        tabManager.selectTab(tabs[0])
        let controller = TabGroupsController()
        let groupID = try XCTUnwrap(controller.createGroup(name: "Work",
                                                           tabIDs: [tabs[0].tabUUID, tabs[1].tabUUID],
                                                           normalTabIDs: tabs.map(\.tabUUID)))

        TabGroupsTabActions(controller: controller, tabManager: tabManager).closeTabs([tabs[0]])

        XCTAssertEqual(controller.state.selectedGroupID, groupID)
        XCTAssertEqual(controller.visibleTabIDs(normalTabIDs: tabManager.normalTabs.map(\.tabUUID)), [tabs[1].tabUUID])
        XCTAssertEqual(tabManager.selectedTab?.tabUUID, tabs[1].tabUUID)
    }

    @MainActor
    func testClosingAllTabsInGroupOpensBlankTabInGroup() throws {
        let tabs = generateTabs(count: 2)
        let tabManager = createInMemoryManager(tabs: tabs)
        tabManager.selectTab(tabs[0])
        let controller = TabGroupsController()
        let groupID = try XCTUnwrap(controller.createGroup(name: "Work",
                                                           tabIDs: [tabs[0].tabUUID],
                                                           normalTabIDs: tabs.map(\.tabUUID)))

        TabGroupsTabActions(controller: controller, tabManager: tabManager).closeTabs([tabs[0]])

        let visibleIDs = controller.visibleTabIDs(normalTabIDs: tabManager.normalTabs.map(\.tabUUID))
        XCTAssertEqual(controller.state.selectedGroupID, groupID)
        XCTAssertEqual(visibleIDs.count, 1)
        XCTAssertEqual(tabManager.selectedTab?.tabUUID, visibleIDs.first)
    }

    @MainActor
    func testClosingAllMobileTabsOpensBlankMobileTab() throws {
        let tabs = generateTabs(count: 2)
        let tabManager = createInMemoryManager(tabs: tabs)
        tabManager.selectTab(tabs[0])
        let controller = TabGroupsController()
        controller.createGroup(name: "Work", tabIDs: [tabs[1].tabUUID], normalTabIDs: tabs.map(\.tabUUID))
        controller.selectGroup(id: nil)

        TabGroupsTabActions(controller: controller, tabManager: tabManager).closeTabs([tabs[0]])

        let visibleIDs = controller.visibleTabIDs(normalTabIDs: tabManager.normalTabs.map(\.tabUUID))
        XCTAssertNil(controller.state.selectedGroupID)
        XCTAssertEqual(visibleIDs.count, 1)
        XCTAssertEqual(tabManager.selectedTab?.tabUUID, visibleIDs.first)
    }

    @MainActor
    func testClosingAllNormalTabsCreatesOneBlankTab() {
        let tabs = generateTabs(count: 2)
        let tabManager = createInMemoryManager(tabs: tabs)
        tabManager.selectTab(tabs[0])
        let controller = TabGroupsController()

        TabGroupsTabActions(controller: controller, tabManager: tabManager).closeTabs(tabs)

        XCTAssertEqual(tabManager.normalTabs.count, 1)
        XCTAssertEqual(tabManager.selectedTab?.tabUUID, tabManager.normalTabs.first?.tabUUID)
        XCTAssertEqual(controller.visibleTabIDs(normalTabIDs: tabManager.normalTabs.map(\.tabUUID)).count, 1)
    }

    @MainActor
    func testMovingActiveTabSwitchesDestinationAndKeepsItSelected() throws {
        let tabs = generateTabs(count: 2)
        let tabManager = createInMemoryManager(tabs: tabs)
        tabManager.selectTab(tabs[0])
        let controller = TabGroupsController()
        let groupID = try XCTUnwrap(controller.createGroup(name: "Work", normalTabIDs: tabs.map(\.tabUUID)))
        controller.selectGroup(id: nil)

        TabGroupsTabActions(controller: controller, tabManager: tabManager).moveTab(tabs[0].tabUUID, to: groupID)

        XCTAssertEqual(controller.state.selectedGroupID, groupID)
        XCTAssertEqual(controller.visibleTabIDs(normalTabIDs: tabManager.normalTabs.map(\.tabUUID)), [tabs[0].tabUUID])
        XCTAssertEqual(tabManager.selectedTab?.tabUUID, tabs[0].tabUUID)
    }
}
