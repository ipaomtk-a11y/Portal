//
//  TabbarController.swift
//  feather
//

import SwiftUI

@available(iOS 18, *)
struct ExtendedTabbarView: View {
    @AppStorage("Feather.tabCustomization") var customization = TabViewCustomization()
    
    var body: some View {
        TabView {
            ForEach(TabEnum.defaultTabs, id: \.self) { tab in
                Tab(tab.title, systemImage: tab.icon) {
                    TabEnum.view(for: tab)
                }
            }
            
            ForEach(TabEnum.customizableTabs, id: \.self) { tab in
                Tab(tab.title, systemImage: tab.icon) {
                    TabEnum.view(for: tab)
                }
                .customizationID("tab.\(tab.rawValue)")
                .defaultVisibility(.hidden, for: .tabBar)
                .customizationBehavior(.reorderable, for: .tabBar, .sidebar)
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tabViewCustomization($customization)
    }
}
