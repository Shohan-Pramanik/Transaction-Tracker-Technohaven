import SwiftUI

@main
struct Transaction_Tracker_TechnohavenApp: App {
    @StateObject private var container = DIContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(container)
        }
    }
}
