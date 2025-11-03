//
//  TodoItem.swift
//  LifeCompanion
//
//  Created by gayeugur on 25.10.2025.
//

import Foundation
import SwiftData

@Model
final class TodoItem {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var dueDate: Date?
    var priority: Priority
    var notes: String?
    var createdAt: Date
    
    enum Priority: String, Codable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
    }
    
    init(title: String, isCompleted: Bool = false, dueDate: Date? = nil, priority: Priority = .medium, notes: String? = nil) {
        self.id = UUID()
        self.title = title
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.priority = priority
        self.notes = notes
        self.createdAt = Date()
    }
}
