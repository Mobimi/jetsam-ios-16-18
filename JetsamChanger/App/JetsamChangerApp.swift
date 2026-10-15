import SwiftUI

@main
struct LaraToolboxApp: App {
    init() {
        // Pre-warm ToolboxManager and probe system on boot
        _ = ToolboxManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}
