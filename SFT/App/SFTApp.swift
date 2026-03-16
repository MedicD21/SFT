import SwiftData
import SwiftUI

@main
struct SFTApp: App {
    private let services = AppServices.live
    private let modelContainer: ModelContainer = {
        do {
            return try ModelContainer(for: FoodLogEntry.self)
        } catch {
            fatalError("Unable to create model container: \(error.localizedDescription)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environment(\.appServices, services)
                .preferredColorScheme(.dark)
                .background(AppTheme.background.ignoresSafeArea())
        }
        .modelContainer(modelContainer)
    }
}

