import SwiftUI
import SwiftData
import BackgroundTasks

@main
struct Mortgage_Rate_TrackerApp: App {
    var sharedModelContainer: ModelContainer

    init() {
        do {
            sharedModelContainer = try ModelContainer(for: RateRecord.self)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        
        // Register the background task when the app initializes
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.yourapp.fetchrates", using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        // Schedule the background task immediately after registration
        scheduleAppRefresh()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }

    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.yourapp.fetchrates")
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "EST")!
        
        // Schedule for 12:00 PM EST
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now)
        components.hour = 12
        components.minute = 0
        components.second = 0
        
        guard let noonToday = calendar.date(from: components) else { return }
        
        // If it's already past noon, schedule for noon tomorrow
        if now > noonToday {
            request.earliestBeginDate = calendar.date(byAdding: .day, value: 1, to: noonToday)
        } else {
            request.earliestBeginDate = noonToday
        }
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Scheduled background task for \(request.earliestBeginDate!).")
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
    func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleAppRefresh() // Reschedule for next time
        
        let fetcher = MortgageRateFetcher(modelContext: sharedModelContainer.mainContext)
        
        let operation = BlockOperation {
            fetcher.fetchData()
        }
        
        task.expirationHandler = {
            operation.cancel()
        }
        
        operation.completionBlock = {
            task.setTaskCompleted(success: !operation.isCancelled)
        }
        
        OperationQueue().addOperation(operation)
    }
}
