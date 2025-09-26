//
//  Mortgage_Rate_TrackerApp.swift
//  Mortgage Rate Tracker
//
//  Created by Robert Wood on 9/25/25.
//

import SwiftUI
import SwiftData

@main
struct Mortgage_Rate_TrackerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            RateRecord.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
