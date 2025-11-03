//
//  HabitItem.swift
//  LifeCompanion
//
//  Created by gayeugur on 28.10.2025.
//

import Foundation
import SwiftUI
import SwiftData

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
        self.entries = []
    }
}
