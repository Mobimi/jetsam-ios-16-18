import SwiftUI

struct ContentView: View {
    @StateObject private var manager = ToolboxManager.shared
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // 1. Inject Dylib (Danh sách app -> chọn dylib -> tiêm)
            DylibInjectorView()
                .tabItem {
                    Label("Inject Dylib", systemImage: "syringe.fill")
                }
                .tag(0)

            // 2. Bật JIT (Danh sách app -> kích hoạt JIT vĩnh viễn on-device)
            JITManagerView()
                .tabItem {
                    Label("Bật JIT", systemImage: "bolt.fill")
                }
                .tag(1)

            // 3. Chỉnh Jetsam (Danh sách app -> ô nhập MB -> Apply)
            AppListView()
                .tabItem {
                    Label("Chỉnh Jetsam", systemImage: "memorychip.fill")
                }
                .tag(2)

            // 4. LaunchDaemon (Tắt/bật dịch vụ ngầm, tối ưu RAM 1-chạm)
            LaunchDaemonsView()
                .tabItem {
                    Label("LaunchDaemon", systemImage: "gearshape.2.fill")
                }
                .tag(3)

            // 5. Console & Kernel Exploit (Kiểm tra status, kích hoạt DarkSword exploit, log terminal)
            SettingsView()
                .tabItem {
                    Label("Console & Exploit", systemImage: "terminal.fill")
                }
                .tag(4)
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
