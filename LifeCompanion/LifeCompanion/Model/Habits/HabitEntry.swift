//
//  HabitEntry.swift
//  LifeCompanion
//
//  Created by gayeugur on 2.11.2025.
//

import Foundation
import SwiftData

@Model
final class HabitEntry {
    var id: UUID
    var date: Date
    var isCompleted: Bool
    var completedAt: Date?
    @Relationship(inverse: \HabitItem.entries) var habit: HabitItem?

    init(habit: HabitItem, date: Date, isCompleted: Bool = false, completedAt: Date? = nil) {
        self.id = UUID()
        self.habit = habit
        self.date = Calendar.current.startOfDay(for: date)
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }
}
