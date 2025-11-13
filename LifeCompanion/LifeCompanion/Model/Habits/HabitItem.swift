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
    var reminderDates: [Date]? // Selected specific dates for reminders
    var createdAt: Date
    var currentStreak: Int = 0
    var longestStreak: Int = 0  
    var lastCompletedDate: Date?
    @Relationship(deleteRule: .cascade) var entries: [HabitEntry]

    init(title: String, notes: String? = nil, frequency: HabitFrequency, targetCount: Int = 1, reminderTime: Date? = nil, reminderDates: [Date]? = nil) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.frequency = frequency
        self.targetCount = targetCount
        self.currentCount = 0
        self.isCompleted = false
        self.reminderTime = reminderTime
        self.reminderDates = reminderDates
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
    
    /// Schedule reminder notifications for this habit
    func scheduleReminderNotification(notificationsEnabled: Bool = true) {
        // Don't schedule if notifications are disabled
        guard notificationsEnabled else {
            // Still remove existing notifications if disabled
            cancelReminderNotifications()
            return
        }
        
        // Remove existing notifications
        cancelReminderNotifications()
        
        let content = UNMutableNotificationContent()
        content.title = "habit.notification.reminder.title".localized
        content.body = String(format: "habit.notification.reminder.body".localized, title)
        content.sound = .default
        content.categoryIdentifier = "HABIT_REMINDER"
        
        let calendar = Calendar.current
        
        // If specific dates are selected, use them
        if let reminderDates = reminderDates, !reminderDates.isEmpty {
            scheduleForSpecificDates(content: content, dates: reminderDates, calendar: calendar)
        }
        // Otherwise, use reminderTime for daily scheduling
        else if let reminderTime = reminderTime {
            scheduleForDailyReminder(content: content, time: reminderTime, calendar: calendar)
        }
    }
    
    private func scheduleForSpecificDates(content: UNMutableNotificationContent, dates: [Date], calendar: Calendar) {
        let timeComponents = reminderTime != nil ? calendar.dateComponents([.hour, .minute], from: reminderTime!) : DateComponents(hour: 9, minute: 0)
        
        for (index, date) in dates.enumerated() {
            // Only schedule for future dates
            guard date > Date() else { continue }
            
            guard let triggerDate = calendar.date(bySettingHour: timeComponents.hour ?? 9,
                                                  minute: timeComponents.minute ?? 0,
                                                  second: 0,
                                                  of: date) else { continue }
            
            let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            
            let identifier = "\(id.uuidString)_date_\(index)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                } else {
                }
            }
        }
    }
    
    private func scheduleForDailyReminder(content: UNMutableNotificationContent, time: Date, calendar: Calendar) {
        let components = calendar.dateComponents([.hour, .minute], from: time)
        
        // Schedule for today and next 30 days
        for i in 0..<30 {
            guard let scheduleDate = calendar.date(byAdding: .day, value: i, to: Date()),
                  let triggerDate = calendar.date(bySettingHour: components.hour ?? 9,
                                                  minute: components.minute ?? 0,
                                                  second: 0,
                                                  of: scheduleDate) else { continue }
            
            let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            
            let identifier = "\(id.uuidString)_daily_\(i)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                } else {
                }
            }
        }
    }
    
    /// Schedule streak celebration notification
    func scheduleStreakCelebrationNotification(notificationsEnabled: Bool = true) {
        // Don't schedule if notifications are disabled
        guard notificationsEnabled else {
            return
        }
        
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
            } else {
            }
        }
    }
    
    /// Cancel all reminder notifications for this habit
    func cancelReminderNotifications() {
        var identifiers: [String] = []
        
        // Add daily reminder notification identifiers
        for i in 0..<30 {
            identifiers.append("\(id.uuidString)_daily_\(i)")
        }
        
        // Add date-specific reminder notification identifiers
        if let reminderDates = reminderDates {
            for i in 0..<reminderDates.count {
                identifiers.append("\(id.uuidString)_date_\(i)")
            }
        }
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    /// Cancel all notifications for this habit
    func cancelAllNotifications() {
        var identifiers: [String] = []
        
        // Add daily reminder notification identifiers
        for i in 0..<30 {
            identifiers.append("\(id.uuidString)_daily_\(i)")
        }
        
        // Add date-specific reminder notification identifiers
        if let reminderDates = reminderDates {
            for i in 0..<reminderDates.count {
                identifiers.append("\(id.uuidString)_date_\(i)")
            }
        }
        
        // Add celebration notification identifiers for common streaks
        for streak in [3, 7, 14, 21, 30, 50, 100] {
            identifiers.append("\(id.uuidString)_celebration_\(streak)")
        }
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
