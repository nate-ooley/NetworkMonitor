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
    var body: some Scene {
        WindowGroup {
            NetworkCanvasView()
                .frame(minWidth: 1000, minHeight: 700)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Refresh Devices") {
                    // TODO: Add refresh action
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
    }
}
