import SwiftUI

@main
struct gAInsApp: App {
    @StateObject private var healthKitManager = HealthKitManager() // Shared instance of HealthKitManager

    var body: some Scene {
        WindowGroup {
            HomeView() // Your root view
                .environmentObject(healthKitManager) // Inject HealthKitManager
        }
    }
}
