import SwiftUI

struct ContentView: View {
    @StateObject private var manager = ProcessManager.shared
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Danh Sách App
            AppListView()
                .tabItem {
                    Label("Danh Sách App", systemImage: "list.bullet.rectangle.portrait.fill")
                }
                .tag(0)

            // Tab 2: Cài Đặt, Trạng Thái Exploit & Console Log
            SettingsView()
                .tabItem {
                    Label("Cài Đặt", systemImage: "gearshape.2.fill")
                }
                .tag(1)
        }
        .accentColor(Theme.accentCyan)
        .onAppear {
            // Configure TabBar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(red: 0.08, green: 0.10, blue: 0.15, alpha: 1.0)
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
    }
}
