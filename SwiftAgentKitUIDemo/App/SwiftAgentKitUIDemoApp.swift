import SwiftUI

@main
struct SwiftAgentKitUIDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentMinSize)
        .commands {
            SidebarCommands()
        }
    }
}
