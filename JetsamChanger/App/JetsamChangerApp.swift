import SwiftUI

@main
struct JetsamChangerApp: App {
    init() {
        // Pre-warm ProcessManager and probe system on boot
        _ = ProcessManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}
