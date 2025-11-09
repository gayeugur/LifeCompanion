//
//  HabitItem.swift
//  LifeCompanion
//
//  Created by gayeugur on 28.10.2025.
//

import Foundation
import SwiftUI
import SwiftData
import UserNotifications

@Model
final class HabitItem: Identifiable {
    var id: UUID
    var title: String
    var notes: String?
    var frequency: HabitFrequency
    var targetCount: Int
    var currentCount: Int
    var isCompleted: Bool
    var reminderTime: Date?
    var createdAt: Date
    var currentStreak: Int = 0
    var longestStreak: Int = 0  
    var lastCompletedDate: Date?
    @Relationship(deleteRule: .cascade) var entries: [HabitEntry]

    init(title: String, notes: String? = nil, frequency: HabitFrequency, targetCount: Int = 1, reminderTime: Date? = nil) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.frequency = frequency
        self.targetCount = targetCount
        self.currentCount = 0
        self.isCompleted = false
        self.reminderTime = reminderTime
        self.createdAt = Date()
        self.currentStreak = 0
        self.longestStreak = 0
        self.lastCompletedDate = nil
        self.entries = []
    }
    
    // Streak hesaplama metodları
    func updateStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let lastCompleted = lastCompletedDate {
            let lastCompletedDay = Calendar.current.startOfDay(for: lastCompleted)
            let daysSinceLastCompletion = Calendar.current.dateComponents([.day], from: lastCompletedDay, to: today).day ?? 0
            
            if daysSinceLastCompletion == 1 {
                // Consecutive day - increase streak
                currentStreak += 1
            } else if daysSinceLastCompletion > 1 {
                // Missed days - reset streak
                currentStreak = 1
            }
            // If daysSinceLastCompletion == 0, it means completed today already
        } else {
            // First completion
            currentStreak = 1
        }
        
        // Update longest streak if needed
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
        
        // Update last completed date
        lastCompletedDate = Date()
    }
    
    func resetStreakIfNeeded() {
        guard let lastCompleted = lastCompletedDate else { return }
        
        let today = Calendar.current.startOfDay(for: Date())
        let lastCompletedDay = Calendar.current.startOfDay(for: lastCompleted)
        let daysSinceLastCompletion = Calendar.current.dateComponents([.day], from: lastCompletedDay, to: today).day ?? 0
        
        // If more than 1 day has passed without completion, reset current streak
        if daysSinceLastCompletion > 1 {
            currentStreak = 0
        }
    }
    
    var streakEmoji: String {
        switch currentStreak {
        case 0: return ""
        case 1...2: return "🔥"
        case 3...6: return "🔥🔥"
        case 7...13: return "🔥🔥🔥"
        case 14...29: return "🏆"
        case 30...: return "👑"
        default: return "🔥"
        }
    }
    
    var streakDescription: String {
        if currentStreak == 0 {
            return "streak.start".localized
        } else if currentStreak == 1 {
            return "streak.single".localized
        } else {
            return String(format: "streak.days".localized, currentStreak, streakEmoji)
        }
    }
    
    // MARK: - Notification Management
    
    /// Schedule daily reminder notification for this habit
    func scheduleReminderNotification() {
        guard let reminderTime = reminderTime else { return }
        
        // Remove existing notifications
        cancelReminderNotifications()
        
        let content = UNMutableNotificationContent()
        content.title = "habit.notification.reminder.title".localized
        content.body = String(format: "habit.notification.reminder.body".localized, title)
        content.sound = .default
        content.categoryIdentifier = "HABIT_REMINDER"
        
        // Schedule for today and next 7 days
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: reminderTime)
        
        for i in 0..<7 {
            guard let scheduleDate = calendar.date(byAdding: .day, value: i, to: Date()),
                  let triggerDate = calendar.date(bySettingHour: components.hour ?? 9,
                                                  minute: components.minute ?? 0,
                                                  second: 0,
                                                  of: scheduleDate) else { continue }
            
            let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            
            let identifier = "\(id.uuidString)_reminder_\(i)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ Failed to schedule habit reminder: \(error)")
                } else {
                    print("✅ Habit reminder scheduled for \(self.title) at \(triggerDate)")
                }
            }
        }
    }
    
    /// Schedule streak celebration notification
    func scheduleStreakCelebrationNotification() {
        let content = UNMutableNotificationContent()
        content.title = "habit.notification.celebration.title".localized
        content.body = String(format: "habit.notification.celebration.body".localized, currentStreak, title, streakEmoji)
        content.sound = .default
        content.categoryIdentifier = "HABIT_CELEBRATION"
        
        // Schedule immediate notification
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let identifier = "\(id.uuidString)_celebration_\(currentStreak)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule celebration notification: \(error)")
            } else {
                print("🎉 Celebration notification scheduled for \(self.title) - \(self.currentStreak) days!")
            }
        }
    }
    
    /// Cancel all reminder notifications for this habit
    func cancelReminderNotifications() {
        var identifiers: [String] = []
        
        // Add reminder notification identifiers
        for i in 0..<7 {
            identifiers.append("\(id.uuidString)_reminder_\(i)")
        }
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        print("🚫 Cancelled reminder notifications for habit: \(title)")
    }
    
    /// Cancel all notifications for this habit
    func cancelAllNotifications() {
        var identifiers: [String] = []
        
        // Add reminder notification identifiers
        for i in 0..<7 {
            identifiers.append("\(id.uuidString)_reminder_\(i)")
        }
        
        // Add celebration notification identifiers for common streaks
        for streak in [3, 7, 14, 21, 30, 50, 100] {
            identifiers.append("\(id.uuidString)_celebration_\(streak)")
        }
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        print("🚫 Cancelled all notifications for habit: \(title)")
    }
}
