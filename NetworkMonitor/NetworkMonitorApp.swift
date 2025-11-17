//
//  NetworkMonitorApp.swift
//  NetworkMonitor
//
//  Created by Nathan Ooley on 11/17/25.
//

import SwiftUI
import CoreData

@main
struct NetworkMonitorApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
