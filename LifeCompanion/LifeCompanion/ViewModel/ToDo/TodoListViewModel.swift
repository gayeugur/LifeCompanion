//
//  TodoListViewModel.swift
//  LifeCompanion
//
//  Created by gayeugur on 25.10.2025.
//

import Foundation
import SwiftUI
import SwiftData

@MainActor
final class TodoListViewModel: ObservableObject {
    @Published var showingAddTodo: Bool = false
    @Published var timeFilter: TimeFilter = .all
    @Published var statusFilter: StatusFilter = .all
    @Published var showingDeleteConfirmation: Bool = false
    @Published var todoToDelete: TodoItem? = nil

    // MARK: - Public API

    func apply(time: TimeFilter) {
        timeFilter = time
    }

    func apply(status: StatusFilter) {
        statusFilter = status
    }

    /// Return sections based on current filters. Groups by day using dueDate if present, otherwise createdAt.
    func sections(from todos: [TodoItem]) -> [TodoSection] {
        let filtered = filteredTodos(from: todos)

        var groups: [Date: [TodoItem]] = [:]
        for todo in filtered {
            let reference = todo.dueDate ?? todo.createdAt
            let key = Calendar.current.startOfDay(for: reference)
            groups[key, default: []].append(todo)
        }

        let sortedKeys = groups.keys.sorted()
        return sortedKeys.map { date in
            TodoSection(
                id: "\(date.timeIntervalSince1970)",
                title: formattedTitle(for: date),
                items: (groups[date] ?? []).sorted(by: sortTodos)
            )
        }
    }

    func delete(_ todo: TodoItem, in context: ModelContext) {
        context.delete(todo)
        try? context.save()
    }
    
    func showDeleteConfirmation(for todo: TodoItem) {
        todoToDelete = todo
        showingDeleteConfirmation = true
    }
    
    func confirmDelete(in context: ModelContext) {
        guard let todo = todoToDelete else { return }
        delete(todo, in: context)
        todoToDelete = nil
    }

    func toggleCompletion(_ todo: TodoItem, in context: ModelContext) {
        todo.isCompleted.toggle()
        try? context.save()
    }

    /// Returns counts for UI badges WITHOUT mutating any @Published state.
    /// timeCounts: count for each TimeFilter applying the currently selected statusFilter.
    /// statusCounts: count for each StatusFilter applying the currently selected timeFilter.
    func counts(for todos: [TodoItem]) -> (time: [TimeFilter: Int], status: [StatusFilter: Int]) {
        var timeCounts: [TimeFilter: Int] = [:]
        var statusCounts: [StatusFilter: Int] = [:]

        for t in TimeFilter.allCases {
            timeCounts[t] = filteredTodos(time: t, status: statusFilter, from: todos).count
        }

        for s in StatusFilter.allCases {
            statusCounts[s] = filteredTodos(time: timeFilter, status: s, from: todos).count
        }

        return (time: timeCounts, status: statusCounts)
    }

    // MARK: - Filtering

    /// Uses the current published filters.
    func filteredTodos(from todos: [TodoItem]) -> [TodoItem] {
        return filteredTodos(time: timeFilter, status: statusFilter, from: todos)
    }

    /// Pure filtering function that does not mutate state.
    private func filteredTodos(time: TimeFilter, status: StatusFilter, from todos: [TodoItem]) -> [TodoItem] {
        let now = Date()
        let cal = Calendar.current

        // Time filtering
        let timeFiltered: [TodoItem] = {
            switch time {
            case .all:
                return todos
            case .today:
                return todos.filter { cal.isDate(($0.dueDate ?? $0.createdAt), inSameDayAs: now) }
            case .thisWeek:
                if let range = cal.dateInterval(of: .weekOfYear, for: now) {
                    return todos.filter {
                        let r = $0.dueDate ?? $0.createdAt
                        return r >= range.start && r < range.end
                    }
                } else {
                    let start = cal.startOfDay(for: now)
                    guard let end = cal.date(byAdding: .day, value: 7, to: start) else { return [] }
                    return todos.filter {
                        let r = $0.dueDate ?? $0.createdAt
                        return r >= start && r < end
                    }
                }
            case .overdue:
                return todos.filter {
                    if let d = $0.dueDate {
                        return d < now && !$0.isCompleted
                    }
                    return false
                }
            }
        }()

        // Status filtering (apply on result of time filtering)
        switch status {
        case .all:
            return timeFiltered
        case .completed:
            return timeFiltered.filter { $0.isCompleted }
        case .incomplete:
            return timeFiltered.filter { !$0.isCompleted }
        }
    }

    // MARK: - Helpers

    private func sortTodos(_ a: TodoItem, _ b: TodoItem) -> Bool {
        if a.isCompleted != b.isCompleted { return !a.isCompleted }
        if let ad = a.dueDate, let bd = b.dueDate { return ad < bd }
        if a.dueDate != nil && b.dueDate == nil { return true }
        if a.dueDate == nil && b.dueDate != nil { return false }
        return a.createdAt < b.createdAt
    }

    private func formattedTitle(for date: Date) -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale.current
        fmt.dateFormat = "d MMMM yyyy, EEEE"
        return fmt.string(from: date)
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
        case .all: return NSLocalizedString("filter.time.all", comment: "All time filters")
        case .today: return NSLocalizedString("filter.time.today", comment: "Today")
        case .thisWeek: return NSLocalizedString("filter.time.thisWeek", comment: "This week")
        case .overdue: return NSLocalizedString("filter.time.overdue", comment: "Overdue")
        }
    }
    var iconName: String {
        switch self {
        case .all: return "tray.full.fill"
        case .today: return "calendar.badge.clock"
        case .thisWeek: return "calendar"
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
        case .all: return .gray
        case .completed: return .green
        case .incomplete: return .red
        }
    }
}