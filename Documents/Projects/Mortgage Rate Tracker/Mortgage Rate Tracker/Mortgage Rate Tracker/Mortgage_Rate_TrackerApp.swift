import SwiftUI
import SwiftData
import BackgroundTasks

@main
struct Mortgage_Rate_TrackerApp: App {
    var sharedModelContainer: ModelContainer
    private var backgroundTaskHandler: BackgroundTaskHandler

    init() {
        do {
            sharedModelContainer = try ModelContainer(for: RateRecord.self)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        
        backgroundTaskHandler = BackgroundTaskHandler(modelContainer: sharedModelContainer)
        backgroundTaskHandler.registerBackgroundTask()
        backgroundTaskHandler.scheduleAppRefresh()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
