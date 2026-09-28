// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import SwiftUI

extension TabTrayViewController {
    private var normalTabPanel: TabDisplayPanelViewController? {
        childPanelControllers.compactMap { $0.topViewController as? TabDisplayPanelViewController }
            .first { $0.panelType == .tabs }
    }

    func setupTabGroupsUI() {
        guard TabGroupsFeatureFlag.isEnabled, let controller = tabGroupsController else { return }
        controller.onChange = { [weak self] _ in
            guard let self else { return }
            self.normalTabPanel?.tabDisplayView.refreshGroupFilter()
            self.refreshTabGroupsUI()
            if let tabManager = self.tabManager {
                store.dispatch(ToolbarAction(numberOfTabs: tabManager.normalTabs.count,
                                             windowUUID: self.windowUUID,
                                             actionType: ToolbarActionType.numberOfTabsChanged))
            }
        }
        normalTabPanel?.tabDisplayView.onSelectionChange = { [weak self] in
            self?.refreshTabGroupsUI()
        }
        normalTabPanel?.tabDisplayView.onCreateGroupForTab = { [weak self] tabID in
            self?.promptForNewGroup(with: [tabID])
        }

        let topHost = UIHostingController(rootView: AnyView(EmptyView()))
        let bottomHost = UIHostingController(rootView: AnyView(EmptyView()))
        tabGroupsTopHost = topHost
        tabGroupsBottomHost = bottomHost
        for (host, height, isTop) in [(topHost, CGFloat(48), true), (bottomHost, CGFloat(56), false)] {
            addChild(host)
            host.view.backgroundColor = .clear
            host.view.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(host.view)
            NSLayoutConstraint.activate([
                host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                host.view.heightAnchor.constraint(equalToConstant: height),
                isTop
                    ? host.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
                    : host.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            ])
            host.didMove(toParent: self)
        }
        refreshTabGroupsUI()
    }

    func refreshTabGroupsUI() {
        guard TabGroupsFeatureFlag.isEnabled,
              let controller = tabGroupsController,
              let tabManager,
              let topHost = tabGroupsTopHost,
              let bottomHost = tabGroupsBottomHost else { return }
        let normalIDs = tabManager.normalTabs.map(\.tabUUID)
        controller.reconcile(normalTabIDs: normalIDs)
        let selectedGroup = controller.state.groups.first { $0.id == controller.state.selectedGroupID }
        let selectedPanel: TabGroupsTrayBarViewModel.Panel = switch tabTrayState.selectedPanel {
        case .tabs: .tabs
        case .privateTabs: .privateTabs
        case .syncedTabs: .syncedTabs
        }
        let viewModel = TabGroupsTrayBarViewModel(
            destinationTitle: selectedGroup?.name ?? "Mobile",
            isGroupSelected: selectedGroup != nil,
            tabCount: controller.visibleTabIDs(normalTabIDs: normalIDs).count,
            selectedPanel: selectedPanel,
            privateTitle: "Private",
            syncedTitle: "Sync",
            doneAccessibilityLabel: "Done")
        let menuModel = TabGroupsContextMenuViewModel(
            showsGroupActions: selectedGroup != nil,
            selectTabsTitle: normalTabPanel?.tabDisplayView.isSelectingTabs == true ? "Done Selecting" : "Select Tabs",
            arrangeTabsTitle: "Arrange Tabs By",
            customizeGroupTitle: "Rename Group",
            closeTabsTitle: "Close Tabs",
            ungroupTitle: "Ungroup",
            tabSettingsTitle: "Tab Settings")
        topHost.rootView = AnyView(TabGroupsTrayTopBar(viewModel: viewModel, onAction: { [weak self] action in
            self?.handleTabGroupsBarAction(action)
        }) {
            TabGroupsContextMenuView(viewModel: menuModel) { [weak self] action in
                self?.handleTabGroupsMenuAction(action)
            }
        })
        bottomHost.rootView = AnyView(TabGroupsTrayBottomBar(viewModel: viewModel) { [weak self] action in
            self?.handleTabGroupsBarAction(action)
        })
        topHost.view.isHidden = tabTrayState.selectedPanel != .tabs
    }

    private func handleTabGroupsBarAction(_ action: TabGroupsTrayBarAction) {
        switch action {
        case .openDestinationPicker:
            showTabGroupsPicker()
        case .openMoreMenu:
            break
        case .addTab:
            if tabTrayState.selectedPanel == .syncedTabs {
                didSelectSection(panelType: .tabs)
            }
            newTabButtonTapped()
        case .selectPanel(let panel):
            let panelType: TabTrayPanelType = switch panel {
            case .tabs: .tabs
            case .privateTabs: .privateTabs
            case .syncedTabs: .syncedTabs
            }
            didSelectSection(panelType: panelType)
        case .done:
            doneButtonTapped()
        }
    }

    private func showTabGroupsPicker() {
        guard tabTrayState.selectedPanel == .tabs else { return }
        let host = UIHostingController(rootView: makeTabGroupsPicker())
        tabGroupsPickerHost = host
        host.view.backgroundColor = .clear
        host.modalPresentationStyle = .pageSheet
        host.sheetPresentationController?.detents = [.medium(), .large()]
        present(host, animated: true)
    }

    private func makeTabGroupsPicker() -> AnyView {
        guard let controller = tabGroupsController else { return AnyView(EmptyView()) }
        let destinations: [TabGroupsPickerViewModel.Destination] = [
            .init(id: "mobile", title: "Mobile", kind: .device)
        ] + controller.state.groups.map {
            .init(id: $0.id.uuidString, title: $0.name, kind: .group)
        }
        let selectedIDs = normalTabPanel?.tabDisplayView.selectedTabIDs ?? []
        let model = TabGroupsPickerViewModel(
            title: "Tab Groups",
            doneAccessibilityLabel: "Done",
            destinations: destinations,
            privateDestination: .init(id: "private", title: "Private", kind: .privateTabs),
            selectedDestinationID: controller.state.selectedGroupID?.uuidString ?? "mobile",
            createEmptyGroupTitle: "New Empty Tab Group",
            createWithSelectedTabsTitle: selectedIDs.isEmpty ? nil : "New Tab Group with \(selectedIDs.count) Tabs")
        return AnyView(TabGroupsPickerView(viewModel: model) { [weak self] action in
            self?.handleTabGroupsPickerAction(action)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground)))
    }

    private func handleTabGroupsPickerAction(_ action: TabGroupsPickerAction) {
        guard let controller = tabGroupsController else { return }
        switch action {
        case .done:
            tabGroupsPickerHost?.dismiss(animated: true)
        case .selectDestination(let id):
            if id == "private" {
                tabGroupsPickerHost?.dismiss(animated: true) { [weak self] in
                    self?.didSelectSection(panelType: .privateTabs)
                }
                return
            }
            controller.selectGroup(id: id == "mobile" ? nil : UUID(uuidString: id))
            if let tabManager,
               let preferredID = controller.preferredTabID(normalTabIDs: tabManager.normalTabs.map(\.tabUUID)),
               let tab = tabManager.getTabForUUID(uuid: preferredID) {
                tabManager.selectTab(tab)
            }
            tabGroupsPickerHost?.dismiss(animated: true)
        case .deleteGroup(let id):
            if let groupID = UUID(uuidString: id) { controller.deleteGroup(id: groupID) }
            tabGroupsPickerHost?.rootView = makeTabGroupsPicker()
        case .moveGroup(let offsets, let destination):
            controller.moveGroups(fromOffsets: offsets, toOffset: destination)
            tabGroupsPickerHost?.rootView = makeTabGroupsPicker()
        case .createEmptyGroup, .createWithSelectedTabs:
            let selectedIDs = action == .createWithSelectedTabs
                ? Array(normalTabPanel?.tabDisplayView.selectedTabIDs ?? []) : []
            tabGroupsPickerHost?.dismiss(animated: true) { [weak self] in
                self?.promptForNewGroup(with: selectedIDs)
            }
        }
    }

    private func promptForNewGroup(with tabIDs: [TabUUID]) {
        guard let controller = tabGroupsController, let tabManager else { return }
        let alert = UIAlertController(title: "New Tab Group", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Group name" }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Create", style: .default) { [weak self, weak alert] _ in
            guard let self else { return }
            let name = alert?.textFields?.first?.text ?? ""
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            controller.createGroup(name: trimmedName.isEmpty ? "New Tab Group" : trimmedName,
                                   tabIDs: tabIDs,
                                   normalTabIDs: tabManager.normalTabs.map(\.tabUUID))
            if let preferredID = controller.preferredTabID(normalTabIDs: tabManager.normalTabs.map(\.tabUUID)),
               let tab = tabManager.getTabForUUID(uuid: preferredID) {
                tabManager.selectTab(tab)
            }
            self.normalTabPanel?.tabDisplayView.isSelectingTabs = false
        })
        present(alert, animated: true)
    }

    private func handleTabGroupsMenuAction(_ action: TabGroupsContextMenuAction) {
        guard let controller = tabGroupsController, let tabManager else { return }
        switch action {
        case .selectTabs:
            if let displayView = normalTabPanel?.tabDisplayView {
                displayView.isSelectingTabs.toggle()
                refreshTabGroupsUI()
            }
        case .arrangeTabs:
            showArrangeTabsOptions()
        case .customizeGroup:
            guard let group = controller.state.groups.first(where: { $0.id == controller.state.selectedGroupID }) else { return }
            let alert = UIAlertController(title: "Rename Tab Group", message: nil, preferredStyle: .alert)
            alert.addTextField { $0.text = group.name }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak alert] _ in
                controller.renameGroup(id: group.id, name: alert?.textFields?.first?.text ?? "")
            })
            present(alert, animated: true)
        case .closeTabs:
            let visibleIDs = Set(controller.visibleTabIDs(normalTabIDs: tabManager.normalTabs.map(\.tabUUID)))
            let tabs = tabManager.normalTabs.filter { visibleIDs.contains($0.tabUUID) }
            let alert = UIAlertController(title: "Close \(tabs.count) Tabs?", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Close Tabs", style: .destructive) { _ in
                tabManager.removeTabs(tabs)
                controller.reconcile(normalTabIDs: tabManager.normalTabs.map(\.tabUUID))
            })
            present(alert, animated: true)
        case .ungroup:
            if let groupID = controller.state.selectedGroupID { controller.deleteGroup(id: groupID) }
        case .tabSettings:
            navigationHandler?.showTabSettings()
        }
    }

    private func showArrangeTabsOptions() {
        let alert = UIAlertController(title: "Arrange Tabs By", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Original Order", style: .default) { [weak self] _ in
            self?.normalTabPanel?.tabDisplayView.sortTabsByTitle = false
        })
        alert.addAction(UIAlertAction(title: "Title", style: .default) { [weak self] _ in
            self?.normalTabPanel?.tabDisplayView.sortTabsByTitle = true
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let popover = alert.popoverPresentationController {
            popover.sourceView = tabGroupsTopHost?.view
            popover.sourceRect = tabGroupsTopHost?.view.bounds ?? .zero
        }
        present(alert, animated: true)
    }

}
