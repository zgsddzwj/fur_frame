//
//  FurFrameApp.swift
//  FurFrame
//
//  Created by Adward on 2026/3/14.
//

import SwiftUI
import SwiftData

@main
struct FurFrameApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PetAsset.self,
        ])
        
        // Pre-create App Group directories to avoid CoreData warnings
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.furframe.app") {
            let supportURL = appGroupURL.appendingPathComponent("Library/Application Support")
            try? FileManager.default.createDirectory(at: supportURL, withIntermediateDirectories: true)
        }
        
        // Try to create ModelContainer with App Group first
        let appGroupConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier("group.com.furframe.app")
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [appGroupConfig])
        } catch {
            // Fallback to default container if App Group fails
            print("App Group container failed, using default: \(error)")
            let defaultConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            do {
                return try ModelContainer(for: schema, configurations: [defaultConfig])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
