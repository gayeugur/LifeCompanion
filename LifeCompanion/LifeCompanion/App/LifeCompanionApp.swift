//
//  LifeCompanionApp.swift
//  LifeCompanion
//
//  Created by gayeugur on 25.10.2025.
//
 
import SwiftUI
import SwiftData
import UserNotifications
import UIKit

// MARK: - App Delegate for Notification Handling
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Set notification center delegate
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    // This method is called when app is in foreground and notification arrives
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        // Show notification even when app is open
        completionHandler([.banner, .sound, .badge])
    }
    
    // This method is called when user taps on notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        // Handle notification tap if needed
        completionHandler()
    }
}

@main
struct LifeCompanionApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
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
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
        
        
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
        
        // Habit completion category
        let habitCompletionCategory = UNNotificationCategory(
            identifier: "HABIT_COMPLETION",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        // Todo reminder category
        let todoReminderCategory = UNNotificationCategory(
            identifier: "TODO_REMINDER",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        // Meditation timer category
        let meditationTimerCategory = UNNotificationCategory(
            identifier: "MEDITATION_TIMER",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            habitReminderCategory,
            habitCelebrationCategory,
            habitCompletionCategory,
            todoReminderCategory,
            meditationTimerCategory
        ])
    }
}
