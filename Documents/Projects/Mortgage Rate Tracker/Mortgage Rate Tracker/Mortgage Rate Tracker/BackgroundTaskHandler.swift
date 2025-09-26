import Foundation
import BackgroundTasks
import SwiftData

class BackgroundTaskHandler: ObservableObject {
    private var modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.arrcwood.MortgageRateTracker.fetchrates", using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
    }

    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.arrcwood.MortgageRateTracker.fetchrates")
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "EST")!
        
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now)
        components.hour = 12
        components.minute = 0
        components.second = 0
        
        guard let noonToday = calendar.date(from: components) else { return }
        
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
        
        let fetcher = MortgageRateFetcher(modelContext: modelContainer.mainContext)
        
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
