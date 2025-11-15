//
//  TodoItem.swift
//  LifeCompanion
//
//  Created by gayeugur on 25.10.2025.
//

import Foundation
import SwiftData
import SwiftUICore

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

// MARK: - Supporting Types

struct TodoSection {
    let id: String
    let title: String
    let items: [TodoItem]
}

enum TimeFilter: String, CaseIterable, Identifiable {
    case all, today, thisWeek, overdue
    var id: String { rawValue }
    var localizedName: String {
        switch self {
        case .all: return "filter.time.all".localized
        case .today: return "filter.time.today".localized
        case .thisWeek: return "filter.time.thisWeek".localized
        case .overdue: return "filter.time.overdue".localized
        }
    }
    var iconName: String {
        switch self {
        case .all: return "tray.full.fill"
        case .today: return "calendar.badge.clock"
        case .thisWeek: return "arrow.up.forward"
        case .overdue: return "exclamationmark.triangle.fill"
        }
    }
    var tint: Color {
        switch self {
        case .all: return .gray
        case .today: return .blue
        case .thisWeek: return .purple
        case .overdue: return .orange
        }
    }
}

enum StatusFilter: String, CaseIterable, Identifiable {
    case all, completed, incomplete
    var id: String { rawValue }
    var localizedName: String {
        switch self {
        case .all: return "filter.status.all".localized
        case .completed: return "filter.status.completed".localized
        case .incomplete: return "filter.status.incomplete".localized
        }
    }
    var iconName: String {
        switch self {
        case .all: return "line.3.horizontal"
        case .completed: return "checkmark.circle.fill"
        case .incomplete: return "circle"
        }
    }
    var tint: Color {
        switch self {
        case .all: return .blue
        case .completed: return .green
        case .incomplete: return .red
        }
    }
}

