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
}
