//
//  HabitListViewModel.swift
//  LifeCompanion
//
//  Created by gayeugur on 28.10.2025.
//

import Foundation
import SwiftData
import SwiftUI
import UserNotifications

@MainActor
final class HabitListViewModel: ObservableObject {
    @Published private(set) var habits: [HabitItem] = []
    @Published var showingAddHabit: Bool = false
    @Published var showingEditHabit: Bool = false
    @Published var editingHabit: HabitItem? = nil
    @Published var showingDeleteConfirmation: Bool = false
    @Published var habitToDelete: HabitItem? = nil
    
    private var settingsManager: SettingsManager?
    private var lastFetchTime: Date?
    private let fetchCacheTimeout: TimeInterval = 1.0 // Cache for 1 second
    
    func configure(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
    }
    
    func fetchHabits(from context: ModelContext) {
        do {
            let fetchDescriptor = FetchDescriptor<HabitItem>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
            let fetched = try context.fetch(fetchDescriptor)
            habits = fetched
        } catch {
            habits = []
        }
    }
    
    func addHabit(title: String,
                  frequency: HabitFrequency,
                  targetCount: Int,
                  reminderTime: Date?,
                  reminderDates: [Date]?,
                  in context: ModelContext) {
        let newHabit = HabitItem(title: title,
                                 frequency: frequency,
                                 targetCount: targetCount,
                                 reminderTime: reminderTime,
                                 reminderDates: reminderDates)
        context.insert(newHabit)
        save(context)
        
        // Schedule reminder notification if time or dates are set
        if reminderTime != nil || reminderDates != nil {
            let notificationsEnabled = settingsManager?.notificationsEnabled ?? true
            newHabit.scheduleReminderNotification(notificationsEnabled: notificationsEnabled)
        }
        
        fetchHabits(from: context)
        showingAddHabit = false
    }
    
    func delete(_ habit: HabitItem, in context: ModelContext) {
        // Cancel all notifications for this habit before deleting
        habit.cancelAllNotifications()
        context.delete(habit)
        save(context)
        fetchHabits(from: context)
    }
    
    func updateHabit(_ habit: HabitItem,
                     title: String,
                     frequency: HabitFrequency,
                     targetCount: Int,
                     reminderTime: Date?,
                     reminderDates: [Date]?,
                     in context: ModelContext) {
        habit.title = title
        habit.frequency = frequency
        habit.targetCount = targetCount
        habit.reminderTime = reminderTime
        habit.reminderDates = reminderDates
        
        // Update notifications
        if reminderTime != nil || reminderDates != nil {
            let notificationsEnabled = settingsManager?.notificationsEnabled ?? true
            habit.scheduleReminderNotification(notificationsEnabled: notificationsEnabled)
        } else {
            habit.cancelReminderNotifications()
        }
        
        save(context)
        fetchHabits(from: context)
    }
    
    func startEditing(_ habit: HabitItem) {
        editingHabit = habit
        showingEditHabit = true
    }
    
    func showDeleteConfirmation(for habit: HabitItem) {
        habitToDelete = habit
        showingDeleteConfirmation = true
    }
    
    func confirmDelete(in context: ModelContext) {
        guard let habit = habitToDelete else { return }
        delete(habit, in: context)
        habitToDelete = nil
    }
    
    func incrementCount(for habit: HabitItem, in context: ModelContext, settingsManager: SettingsManager? = nil) {
        // Don't increment if already completed
        guard !habit.isCompleted else {
            return 
        }
        
        let wasCompleted = habit.isCompleted
        habit.currentCount += 1
        
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        
        // Always ensure there's an entry for today
        let todayEntry = habit.entries.first(where: { cal.isDate($0.date, inSameDayAs: today) }) ?? {
            let newEntry = HabitEntry(habit: habit, date: today, isCompleted: false, completedAt: nil)
            context.insert(newEntry)
            return newEntry
        }()
        
        if habit.currentCount >= habit.targetCount && !wasCompleted {
            habit.isCompleted = true
            
            // Update streak when habit is completed
            let oldStreak = habit.currentStreak
            habit.updateStreak()
            
            // Mark today's entry as completed
            todayEntry.isCompleted = true
            todayEntry.completedAt = Date()
            
            // Cancel reminder notifications since habit is now completed
            habit.cancelReminderNotifications()
            
            // Send completion notification only for newly completed habits (wasCompleted = false)
            sendCompletionNotification(for: habit, settingsManager: settingsManager, streakIncreased: habit.currentStreak > oldStreak)
        } else if habit.currentCount >= habit.targetCount && wasCompleted {
        }
        
        save(context)
        fetchHabits(from: context)
    }
    
    private func save(_ context: ModelContext) {
        do {
            try context.save()
        } catch {
            // Handle error silently
        }
    }
    
    func resetIfNeeded(in context: ModelContext, settingsManager: SettingsManager? = nil) {
        self.settingsManager = settingsManager
        
        let calendar = Calendar.current
        let now = Date()
        
        // Get auto reset time from settings or default to midnight
        let autoResetTime = settingsManager?.autoResetTime ?? {
            calendar.date(bySettingHour: 0, minute: 0, second: 0, of: now) ?? now
        }()
        
        // Get reset time for today
        let resetComponents = calendar.dateComponents([.hour, .minute], from: autoResetTime)
        guard let todayResetTime = calendar.date(bySettingHour: resetComponents.hour ?? 0,
                                                 minute: resetComponents.minute ?? 0,
                                                 second: 0,
                                                 of: now) else {
            return 
        }
        
        let lastResetKey = "lastHabitResetDate"
        let lastResetTimestamp = UserDefaults.standard.double(forKey: lastResetKey)
        let lastResetDate = lastResetTimestamp > 0 ? Date(timeIntervalSince1970: lastResetTimestamp) : Date.distantPast
        
        // Debug logging
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        // Check if we need to reset
        // Case 1: If it's a new day and we're past the reset time, reset
        // Case 2: If it's the same day but we're past reset time and haven't reset since reset time
        let needsReset: Bool
        
        let isNewDay = !calendar.isDate(lastResetDate, inSameDayAs: now)
        let isPastResetTime = now >= todayResetTime
        
        if isNewDay {
            // New day: reset if we're past today's reset time
            needsReset = isPastResetTime
        } else {
            // Same day: reset if we're past reset time and last reset was before today's reset time
            let lastResetBeforeToday = lastResetDate < todayResetTime
            needsReset = isPastResetTime && lastResetBeforeToday

        }
        
        
        guard needsReset else {
            return 
        }
        
        let todayStart = calendar.startOfDay(for: now)
        
        for habit in habits {
            let hasTodayEntry = habit.entries.contains { calendar.isDate($0.date, inSameDayAs: todayStart) }
            
            if hasTodayEntry == false {
                let entry = HabitEntry(habit: habit, date: todayStart, isCompleted: false, completedAt: nil)
                context.insert(entry)
            }
            
            // Reset streak if needed (when days are missed)
            habit.resetStreakIfNeeded()
            
            habit.currentCount = 0
            habit.isCompleted = false
            
            // Reschedule reminder notifications for the new day
            if let settingsManager = settingsManager {
                habit.scheduleReminderNotification(notificationsEnabled: settingsManager.notificationsEnabled)
            }
        }
        
        save(context)
        
        // Save the timestamp when reset was performed
        UserDefaults.standard.set(now.timeIntervalSince1970, forKey: lastResetKey)
    }
    
    func checkAutoReset(in context: ModelContext, settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
        resetIfNeeded(in: context, settingsManager: settingsManager)
    }
    
    func ensureTodayEntries(in context: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        for habit in habits {
            let hasTodayEntry = habit.entries.contains { calendar.isDate($0.date, inSameDayAs: today) }
            
            if !hasTodayEntry {
                let entry = HabitEntry(habit: habit, date: today, isCompleted: false, completedAt: nil)
                context.insert(entry)
            }
        }
        
        save(context)
    }
    
    func addHistoryEntry(for habit: HabitItem, on date: Date, isCompleted: Bool, in context: ModelContext) {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        
        // Check if entry already exists for this date
        let existingEntry = habit.entries.first { calendar.isDate($0.date, inSameDayAs: targetDate) }
        
        if let existing = existingEntry {
            // Update existing entry
            existing.isCompleted = isCompleted
            existing.completedAt = isCompleted ? date : nil
        } else {
            // Create new entry for past date
            let newEntry = HabitEntry(habit: habit, date: targetDate, isCompleted: isCompleted, completedAt: isCompleted ? date : nil)
            context.insert(newEntry)
        }
        
        save(context)
        fetchHabits(from: context)
    }
    
    private func sendCompletionNotification(for habit: HabitItem, settingsManager: SettingsManager?, streakIncreased: Bool) {
        // Don't send notification if settings manager is not available or notifications disabled
        guard let settings = settingsManager, settings.notificationsEnabled else {
            return 
        }
        
        // Extra safety: Don't send notification if habit was already completed before this session
        guard habit.isCompleted else {
            return
        }
        
        // If streak increased and it's a milestone, send celebration notification
        if streakIncreased && settings.shouldShowStreakCelebration(for: habit.currentStreak) {
            habit.scheduleStreakCelebrationNotification(notificationsEnabled: settings.notificationsEnabled)
        } 
        // Otherwise, send a simple completion notification
        else {
            scheduleSimpleCompletionNotification(for: habit)
        }
    }
    
    private func scheduleSimpleCompletionNotification(for habit: HabitItem) {
        let content = UNMutableNotificationContent()
        content.title = "habit.notification.completed.title".localized
        content.body = String(format: "habit.notification.completed.body".localized, habit.title)
        content.sound = .default
        content.categoryIdentifier = "HABIT_COMPLETION"
        
        // Schedule immediate notification
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let identifier = "\(habit.id.uuidString)_completed_\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            // Handle silently
        }
    }
}
