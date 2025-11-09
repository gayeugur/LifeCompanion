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
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var feedbackManager = FeedbackManager()
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var languageManager = LanguageManager.shared

    init() {
        // Handle migration for new streak features
        MigrationHelper.clearDataIfNeeded()
        
        do {
            // Configure ModelContainer with migration options
            let schema = Schema([
                TodoItem.self,
                HabitItem.self,
                HabitEntry.self,
                WaterIntake.self,
                MedicationEntry.self,
                GameScore.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            
            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            print("❌ ModelContainer error: \(error)")
            
            // Fallback: Try to delete and recreate the container
            do {
                let url = URL.applicationSupportDirectory.appending(path: "default.store")
                try? FileManager.default.removeItem(at: url)
                
                let schema = Schema([
                    TodoItem.self,
                    HabitItem.self,
                    HabitEntry.self,
                    WaterIntake.self, 
                    MedicationEntry.self,
                    GameScore.self
                ])
                
                container = try ModelContainer(for: schema)
                print("✅ ModelContainer recreated successfully")
            } catch {
                fatalError("Could not initialize ModelContainer even after cleanup: \(error)")
            }
        }
        
        requestNotificationPermission()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .environmentObject(themeManager)
                .environmentObject(feedbackManager)
                .environmentObject(settingsManager)
                .environmentObject(languageManager)
                .environmentObject(DataManager())
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
        
        // Setup notification categories
        setupNotificationCategories()
    }
    
    private func setupNotificationCategories() {
        // Habit reminder category
        let habitReminderCategory = UNNotificationCategory(
            identifier: "HABIT_REMINDER",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        // Habit celebration category
        let habitCelebrationCategory = UNNotificationCategory(
            identifier: "HABIT_CELEBRATION",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            habitReminderCategory,
            habitCelebrationCategory
        ])
    }
}
