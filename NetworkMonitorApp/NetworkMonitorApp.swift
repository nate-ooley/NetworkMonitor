import SwiftUI
import CoreData

@main
struct NetworkMonitorApp: App {
    let persistenceController = PersistenceController.shared
    
    // Initialize the monitor logic here.
    // @StateObject ensures this instance lives for the entire lifetime of the app.
    @StateObject private var networkMonitor = NetworkStatusMonitor()
    @StateObject private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            DeviceListView()
                // Inject the Database Context
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                // Inject the Network Monitor Logic
                .environmentObject(networkMonitor)
                .environmentObject(themeManager)
        }
    }
}

//
//  NetworkMonitorApp.swift
//  NetworkMonitor
//
//  Created by Nathan Ooley on 11/17/25.
//

