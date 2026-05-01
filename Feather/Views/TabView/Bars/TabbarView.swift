//
//  TabbarView.swift
//  feather
//

import SwiftUI

struct TabbarView: View {
    @State private var selectedTab: TabEnum = .sources

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                ForEach(TabEnum.defaultTabs, id: \.self) { tab in
                    TabEnum.view(for: tab)
                        .tag(tab)
                        .toolbar(.hidden, for: .tabBar)
                }
            }

            customTabBar
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    private var customTabBar: some View {
        HStack(spacing: 6) {
            ForEach(TabEnum.defaultTabs, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 10)
        .padding(.horizontal, 18)
        .padding(.bottom, 12)
    }

    private func tabButton(_ tab: TabEnum) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 5) {
                ZStack {
                    if selectedTab == tab {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.indigo, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 42, height: 42)
                            .shadow(color: .blue.opacity(0.35), radius: 10, x: 0, y: 5)
                    }

                    Image(systemName: tab.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(selectedTab == tab ? .white : .secondary)
                }

                Text(tab.title)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(selectedTab == tab ? .primary : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
