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

    func fetchHabits(from context: ModelContext) {
        let fetchDescriptor = FetchDescriptor<HabitItem>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        if let fetched = try? context.fetch(fetchDescriptor) {
            habits = fetched
        }
    }

    func addHabit(title: String,
                  frequency: HabitFrequency,
                  targetCount: Int,
                  reminderTime: Date?,
                  in context: ModelContext) {
        let newHabit = HabitItem(title: title,
                                 frequency: frequency,
                                 targetCount: targetCount,
                                 reminderTime: reminderTime)
        context.insert(newHabit)
        save(context)
        fetchHabits(from: context)
    }

    func delete(_ habit: HabitItem, in context: ModelContext) {
        context.delete(habit)
        save(context)
        fetchHabits(from: context)
    }

    func incrementCount(for habit: HabitItem, in context: ModelContext) {
        habit.currentCount += 1

        if habit.currentCount >= habit.targetCount {
            habit.isCompleted = true

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
        } catch {
            print("❌ Save error: \(error)")
        }
    }
    
    func resetIfNeeded(in context: ModelContext) {
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: Date())

        let lastReset = UserDefaults.standard.object(forKey: "lastResetDate") as? Date
        let last = lastReset != nil ? cal.startOfDay(for: lastReset!) : .distantPast

        guard last < todayStart else { return }

        for habit in habits {

            let hasTodayEntry = habit.entries.contains { cal.isDate($0.date, inSameDayAs: todayStart) }

            if hasTodayEntry == false {
                let entry = HabitEntry(habit: habit, date: todayStart, isCompleted: false, completedAt: nil)
                context.insert(entry)
            }

            habit.currentCount = 0
            habit.isCompleted = false
        }

        save(context)
        UserDefaults.standard.set(Date(), forKey: "lastResetDate")
    }


    
}
