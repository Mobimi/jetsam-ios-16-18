import SwiftUI

struct ContentView: View {
    @StateObject private var manager = ToolboxManager.shared
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 0: Tiêm Tweak (Dylib Injector)
            DylibInjectorView()
                .tabItem {
                    Label("Tiêm Tweak", systemImage: "syringe.fill")
                }
                .tag(0)

            // Tab 1: Dịch Vụ Ngầm (LaunchDaemons)
            LaunchDaemonsView()
                .tabItem {
                    Label("Dịch Vụ Ngầm", systemImage: "gearshape.arrow.triangle.2.circlepath")
                }
                .tag(1)

            // Tab 2: Tiện Ích Exploit (Gaming, JIT, Fake GPS, Dynamic Island)
            ExploitTweaksView()
                .tabItem {
                    Label("Tiện Ích", systemImage: "wand.and.stars")
                }
                .tag(2)

            // Tab 3: Cài Đặt, Trạng Thái Exploit & Console Log
            SettingsView()
                .tabItem {
                    Label("Console & Exploit", systemImage: "terminal.fill")
                }
                .tag(3)
        }
        .accentColor(Theme.accentCyan)
        .onAppear {
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
