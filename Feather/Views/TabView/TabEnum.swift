//
//  TabEnum.swift
//  IPAOMTK
//
//  Modified for IPAOMTK
//

import SwiftUI
import NimbleViews

enum TabEnum: String, CaseIterable, Hashable {
    case home      
    case sources
    case library
    case settings
    case certificates
    
    var title: String {
        switch self {
        case .home:         return .localized("Home") //
        case .sources:      return .localized("Sources")
        case .library:      return .localized("Library")
        case .settings:     return .localized("Settings")
        case .certificates: return .localized("Certificates")
        }
    }
    
    var icon: String {
        switch self {
        case .home:         return "house.fill" //
        case .sources:      return "globe.desk"
        case .library:      return "square.grid.2x2"
        case .settings:     return "gearshape.2"
        case .certificates: return "person.text.rectangle"
        }
    }
    
    @ViewBuilder
    static func view(for tab: TabEnum) -> some View {
        switch tab {
        case .home:         HomeView() //  HomeView
        case .sources:      SourcesView()
        case .library:      LibraryView()
        case .settings:     SettingsView()
        case .certificates: NBNavigationView(.localized("Certificates")) { CertificatesView() }
        }
    }
    
    static var defaultTabs: [TabEnum] {
        return [
            .home,    //
            .sources,
            .library,
            .settings
        ]
    }
    
    static var customizableTabs: [TabEnum] {
        return [
            .certificates
        ]
    }
}
