import SwiftUI

struct TabbarView: View {
    @Binding var selectedTab: TabEnum

    var body: some View {
        ZStack {
            HStack {
                tabItem(.home, "house")
                Spacer()
                tabItem(.sources, "globe")
                Spacer()
                tabItem(.library, "square.grid.2x2")
                Spacer()
                tabItem(.settings, "gearshape")
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 14)
            .background(
                BlurView(style: .systemUltraThinMaterialDark)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color.blue.opacity(0.3), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    private func tabItem(_ tab: TabEnum, _ icon: String) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(selectedTab == tab ? Color.blue : Color.gray)

                if selectedTab == tab {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 6, height: 6)
                }
            }
        }
    }
}
