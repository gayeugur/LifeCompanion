//
//  LifeCompanionApp.swift
//  LifeCompanion
//
//  Created by gayeugur on 25.10.2025.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct LifeCompanionApp: App {
    
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: TodoItem.self, HabitItem.self, WaterIntake.self)
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
        
        requestNotificationPermission()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
}
