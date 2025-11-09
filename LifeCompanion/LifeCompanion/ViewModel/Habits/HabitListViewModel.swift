//
//  HabitListViewModel.swift
//  LifeCompanion
//
//  Created by gayeugur on 28.10.2025.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
final class HabitListViewModel: ObservableObject {
    @Published var habits: [HabitItem] = []
    @Published var showingAddHabit: Bool = false
    @Published var showingEditHabit: Bool = false
    @Published var editingHabit: HabitItem? = nil
    @Published var showingDeleteConfirmation: Bool = false
    @Published var habitToDelete: HabitItem? = nil
    
    private var settingsManager: SettingsManager?

    func fetchHabits(from context: ModelContext) {
        do {
            let fetchDescriptor = FetchDescriptor<HabitItem>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
            let fetched = try context.fetch(fetchDescriptor)
            habits = fetched
            print("📋 Fetched \(habits.count) habits from database")
        } catch {
            print("❌ Error fetching habits: \(error)")
            habits = []
        }
    }

    func addHabit(title: String,
                  frequency: HabitFrequency,
                  targetCount: Int,
                  reminderTime: Date?,
                  in context: ModelContext) {
        print("🔄 Adding habit: '\(title)' with frequency: \(frequency)")
        let newHabit = HabitItem(title: title,
                                 frequency: frequency,
                                 targetCount: targetCount,
                                 reminderTime: reminderTime)
        context.insert(newHabit)
        save(context)
        
        // Schedule reminder notification if time is set
        if reminderTime != nil {
            newHabit.scheduleReminderNotification()
        }
        
        fetchHabits(from: context)
        print("✅ Habit added successfully. Total habits: \(habits.count)")
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
                     in context: ModelContext) {
        habit.title = title
        habit.frequency = frequency
        habit.targetCount = targetCount
        habit.reminderTime = reminderTime
        
        // Update notifications
        if let _ = reminderTime {
            habit.scheduleReminderNotification()
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

    func incrementCount(for habit: HabitItem, in context: ModelContext) {
        habit.currentCount += 1

        if habit.currentCount >= habit.targetCount {
            habit.isCompleted = true
            
            // Update streak when habit is completed
            habit.updateStreak()

            let cal = Calendar.current
            let today = cal.startOfDay(for: Date())

            if let entry = habit.entries.first(where: { cal.isDate($0.date, inSameDayAs: today) }) {
                entry.isCompleted = true
                entry.completedAt = Date()
            }
        }

        save(context)
        fetchHabits(from: context)
    }

    private func save(_ context: ModelContext) {
        do {
            try context.save()
            print("✅ Context saved successfully")
        } catch {
            print("❌ Save error: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("❌ Error details: \(nsError.userInfo)")
            }
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
                                                 of: now) else { return }
        
        let lastResetKey = "lastHabitResetDate"
        let lastResetString = UserDefaults.standard.string(forKey: lastResetKey) ?? ""
        
        // Create today's date string for comparison
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: now)
        
        // Check if we need to reset (new day and past reset time)
        let needsReset = lastResetString != todayString && now >= todayResetTime
        
        guard needsReset else { return }
        
        print("🔄 Habit auto-reset triggered at \(dateFormatter.string(from: now)) - Reset time: \(resetComponents.hour ?? 0):\(String(format: "%02d", resetComponents.minute ?? 0))")

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
        }

        save(context)
        UserDefaults.standard.set(todayString, forKey: lastResetKey)
        print("✅ Habit reset completed for \(habits.count) habits")
    }
    
    func checkAutoReset(in context: ModelContext, settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
        resetIfNeeded(in: context, settingsManager: settingsManager)
    }


    
}
