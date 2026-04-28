//
//  TabEnum.swift
//  feather
//
//  Modified for AshteMobile
//

import SwiftUI
import NimbleViews

enum TabEnum: String, CaseIterable, Hashable {
    case home        // ١. زیادکردنی کیسێکی نوێ
    case sources
    case library
    case settings
    case certificates
    
    var title: String {
        switch self {
        case .home:         return .localized("Home") // ناوی بەشەکە
        case .sources:      return .localized("Sources")
        case .library:      return .localized("Library")
        case .settings:     return .localized("Settings")
        case .certificates: return .localized("Certificates")
        }
    }
    
    var icon: String {
        switch self {
        case .home:         return "house.fill" // ئایکۆنی ماڵەکە
        case .sources:      return "globe.desk"
        case .library:      return "square.grid.2x2"
        case .settings:     return "gearshape.2"
        case .certificates: return "person.text.rectangle"
        }
    }
    
    @ViewBuilder
    static func view(for tab: TabEnum) -> some View {
        switch tab {
        case .home:         HomeView() // ٢. لێرە پێویستە فایلی HomeView دروست بکەیت
        case .sources:      SourcesView()
        case .library:      LibraryView()
        case .settings:     SettingsView()
        case .certificates: NBNavigationView(.localized("Certificates")) { CertificatesView() }
        }
    }
    
    static var defaultTabs: [TabEnum] {
        return [
            .home,    // ٣. دانانی ماڵەوە وەک یەکەم بەش لە لیستەکەدا
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
