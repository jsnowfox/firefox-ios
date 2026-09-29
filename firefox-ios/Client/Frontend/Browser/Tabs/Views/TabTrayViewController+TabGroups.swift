// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import SwiftUI
import UIKit

extension TabTrayViewController {
    private var normalTabPanel: TabDisplayPanelViewController? {
        childPanelControllers.compactMap { $0.topViewController as? TabDisplayPanelViewController }
            .first { $0.panelType == .tabs }
    }

    func setupTabGroupsUI() {
        guard TabGroupsFeatureFlag.isEnabled, let controller = tabGroupsController else { return }
        guard tabGroupsTopHost == nil else { return }
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
        let backdrop = TabGroupsSelectionBackdropView()
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        backdrop.isHidden = true
        view.insertSubview(backdrop, belowSubview: bottomHost.view)
        NSLayoutConstraint.activate([
            backdrop.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdrop.topAnchor.constraint(equalTo: bottomHost.view.topAnchor, constant: -56),
            backdrop.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        tabGroupsSelectionBackdrop = backdrop
        refreshTabGroupsUI()
    }

    func refreshTabGroupsUI() {
        guard TabGroupsFeatureFlag.isEnabled,
              let controller = tabGroupsController,
              let tabManager,
              let topHost = tabGroupsTopHost,
              let bottomHost = tabGroupsBottomHost else { return }
        controller.reconcile(normalTabIDs: tabManager.normalTabs.map(\.tabUUID))
        let normalIDs = tabManager.normalTabs.map(\.tabUUID)
        if tabTrayState.selectedPanel == .tabs,
           !isAddingTabToEmptyGroup,
           let groupID = controller.state.selectedGroupID,
           controller.visibleTabIDs(normalTabIDs: normalIDs).isEmpty {
            isAddingTabToEmptyGroup = true
            defer { isAddingTabToEmptyGroup = false }
            let tab = tabManager.addTab(nil, isPrivate: false)
            controller.assignTab(tab.tabUUID,
                                 to: groupID,
                                 normalTabIDs: tabManager.normalTabs.map(\.tabUUID))
            tabManager.selectTab(tab)
            return
        }
        let selectedGroup = controller.state.groups.first { $0.id == controller.state.selectedGroupID }
        let displayView = normalTabPanel?.tabDisplayView
        let isSelectingTabs = tabTrayState.selectedPanel == .tabs && displayView?.isSelectingTabs == true
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
            doneAccessibilityLabel: "Done",
            groupEmoji: selectedGroup?.emoji,
            groupColor: selectedGroup?.color.swiftUIColor,
            selectedTabCount: isSelectingTabs ? displayView?.selectedTabIDs.count : nil)
        let menuModel = TabGroupsContextMenuViewModel(
            showsGroupActions: selectedGroup != nil,
            selectTabsTitle: "Select Tabs",
            arrangeTabsTitle: "Arrange Tabs By",
            customizeGroupTitle: "Customize Group",
            closeTabsTitle: "Close Tabs",
            ungroupTitle: "Ungroup",
            tabSettingsTitle: "Tab Settings",
            sortsByTitle: normalTabPanel?.tabDisplayView.sortTabsByTitle == true)
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
        tabGroupsSelectionBackdrop?.isHidden = !isSelectingTabs
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
            normalTabPanel?.tabDisplayView.isSelectingTabs = false
            let panelType: TabTrayPanelType = switch panel {
            case .tabs: .tabs
            case .privateTabs: .privateTabs
            case .syncedTabs: .syncedTabs
            }
            didSelectSection(panelType: panelType)
        case .done:
            doneButtonTapped()
        case .finishSelection:
            normalTabPanel?.tabDisplayView.isSelectingTabs = false
            refreshTabGroupsUI()
        case .createGroupFromSelection:
            guard let selectedIDs = normalTabPanel?.tabDisplayView.selectedTabIDs,
                  !selectedIDs.isEmpty else { return }
            showGroupEditor(tabIDs: Array(selectedIDs))
        case .moveSelectionToGroup:
            showMoveSelectedTabsMenu()
        case .closeSelectedTabs:
            guard let selectedIDs = normalTabPanel?.tabDisplayView.selectedTabIDs,
                  !selectedIDs.isEmpty,
                  let tabManager else { return }
            let tabs = tabManager.normalTabs.filter { selectedIDs.contains($0.tabUUID) }
            let alert = UIAlertController(title: "Close \(tabs.count) Tabs?", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Close Tabs", style: .destructive) { [weak self] _ in
                self?.normalTabPanel?.tabDisplayView.isSelectingTabs = false
                tabManager.removeTabs(tabs)
                self?.refreshTabGroupsUI()
            })
            present(alert, animated: true)
        }
    }

    private func showMoveSelectedTabsMenu() {
        guard let selectedIDs = normalTabPanel?.tabDisplayView.selectedTabIDs,
              !selectedIDs.isEmpty,
              let controller = tabGroupsController else { return }

        let alert = UIAlertController(title: "Move \(selectedIDs.count) Tabs To",
                                      message: nil,
                                      preferredStyle: .actionSheet)
        if controller.state.selectedGroupID != nil {
            alert.addAction(UIAlertAction(title: "Mobile", style: .default) { [weak self] _ in
                self?.moveSelectedTabs(selectedIDs, to: nil)
            })
        }
        for group in controller.state.groups where group.id != controller.state.selectedGroupID {
            alert.addAction(UIAlertAction(title: "\(group.emoji) \(group.name)", style: .default) { [weak self] _ in
                self?.moveSelectedTabs(selectedIDs, to: group.id)
            })
        }
        if alert.actions.isEmpty {
            alert.message = "Create another group to move these tabs."
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.popoverPresentationController?.sourceView = tabGroupsBottomHost?.view ?? view
        alert.popoverPresentationController?.sourceRect = tabGroupsBottomHost?.view.bounds ?? view.bounds
        present(alert, animated: true)
    }

    private func moveSelectedTabs(_ selectedIDs: Set<TabUUID>, to groupID: UUID?) {
        guard let controller = tabGroupsController, let tabManager else { return }
        let normalIDs = tabManager.normalTabs.map(\.tabUUID)
        let movingIDs = normalIDs.filter { selectedIDs.contains($0) }
        normalTabPanel?.tabDisplayView.isSelectingTabs = false
        controller.moveTabs(movingIDs, to: groupID, normalTabIDs: normalIDs)
        if let tabID = controller.preferredTabID(normalTabIDs: normalIDs),
           let tab = tabManager.getTabForUUID(uuid: tabID) {
            tabManager.selectTab(tab)
        }
        refreshTabGroupsUI()
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
            .init(id: $0.id.uuidString,
                  title: $0.name,
                  kind: .group,
                  emoji: $0.emoji,
                  color: $0.color.swiftUIColor)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
                self?.showGroupEditor(tabIDs: selectedIDs)
            }
        }
    }

    private func promptForNewGroup(with tabIDs: [TabUUID]) {
        showGroupEditor(tabIDs: tabIDs)
    }

    private func showGroupEditor(group: TabGroup? = nil, tabIDs: [TabUUID] = []) {
        guard let controller = tabGroupsController, let tabManager else { return }
        let editor = TabGroupEditorView(name: group?.name ?? "",
                                        emoji: group?.emoji ?? "🗂️",
                                        color: group?.color ?? .orange,
                                        isEditing: group != nil,
                                        onCancel: { [weak self] in self?.dismiss(animated: true) },
                                        onSave: { [weak self] name, emoji, color in
            guard let self else { return }
            if let group {
                controller.updateGroup(id: group.id, name: name, emoji: emoji, color: color)
            } else {
                let initialTabIDs: [TabUUID]
                if tabIDs.isEmpty {
                    initialTabIDs = [tabManager.addTab(nil, isPrivate: false).tabUUID]
                } else {
                    initialTabIDs = tabIDs
                }
                controller.createGroup(name: name,
                                       emoji: emoji,
                                       color: color,
                                       tabIDs: initialTabIDs,
                                       normalTabIDs: tabManager.normalTabs.map(\.tabUUID))
                if let preferredID = controller.preferredTabID(normalTabIDs: tabManager.normalTabs.map(\.tabUUID)),
                   let tab = tabManager.getTabForUUID(uuid: preferredID) {
                    tabManager.selectTab(tab)
                }
                self.normalTabPanel?.tabDisplayView.isSelectingTabs = false
            }
            self.dismiss(animated: true)
            self.refreshTabGroupsUI()
        })
        let host = UIHostingController(rootView: editor)
        host.modalPresentationStyle = .pageSheet
        host.sheetPresentationController?.detents = [.large()]
        present(host, animated: true)
    }

    private func handleTabGroupsMenuAction(_ action: TabGroupsContextMenuAction) {
        guard let controller = tabGroupsController, let tabManager else { return }
        switch action {
        case .selectTabs:
            if let displayView = normalTabPanel?.tabDisplayView {
                displayView.isSelectingTabs = true
                refreshTabGroupsUI()
            }
        case .arrangeTabsByOriginalOrder:
            normalTabPanel?.tabDisplayView.sortTabsByTitle = false
            refreshTabGroupsUI()
        case .arrangeTabsByTitle:
            normalTabPanel?.tabDisplayView.sortTabsByTitle = true
            refreshTabGroupsUI()
        case .customizeGroup:
            guard let group = controller.state.groups.first(where: { $0.id == controller.state.selectedGroupID }) else { return }
            showGroupEditor(group: group)
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

}

private final class TabGroupsSelectionBackdropView: UIVisualEffectView {
    private let fadeMask = CAGradientLayer()

    init() {
        super.init(effect: UIBlurEffect(style: .systemMaterial))
        isUserInteractionEnabled = false
        fadeMask.colors = [UIColor.clear.cgColor, UIColor.white.cgColor, UIColor.white.cgColor]
        fadeMask.locations = [0, 0.45, 1]
        layer.mask = fadeMask
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        fadeMask.frame = bounds
    }
}
