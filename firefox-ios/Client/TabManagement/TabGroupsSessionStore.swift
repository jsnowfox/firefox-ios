// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

@MainActor
enum TabGroupsSessionStore {
    private static var controllers = [WindowUUID: TabGroupsController]()

    static func controller(for windowUUID: WindowUUID) -> TabGroupsController {
        if let controller = controllers[windowUUID] { return controller }
        let controller = TabGroupsController()
        controllers[windowUUID] = controller
        return controller
    }

    static func removeController(for windowUUID: WindowUUID) {
        controllers[windowUUID] = nil
    }
}
