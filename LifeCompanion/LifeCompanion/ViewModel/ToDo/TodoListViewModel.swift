//
//  TodoListViewModel.swift
//  LifeCompanion
//
//  Created by gayeugur on 25.10.2025.
//

import Foundation
import SwiftUI
import SwiftData
import UserNotifications

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

        let sortedKeys = groups.keys.sorted(by: >) // Latest date first
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
        
        // Cancel notification when todo is completed
        if todo.isCompleted {
            cancelNotification(for: todo)
        }
        
        try? context.save()
    }
    
    private func cancelNotification(for todo: TodoItem) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [todo.id.uuidString])
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
                // Show upcoming tasks (future tasks, not completed)
                let today = cal.startOfDay(for: now)
                return todos.filter { todo in
                    guard !todo.isCompleted else { return false }
                    let taskDate = todo.dueDate ?? todo.createdAt
                    return taskDate > today
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
        // First, prioritize incomplete tasks
        if a.isCompleted != b.isCompleted { return !a.isCompleted }
        
        // Second, prioritize "günün önerisi" (today's suggestion) at the top
        let isASuggestion = a.title.lowercased().contains("günün önerisi") || a.title.lowercased().contains("today's suggestion")
        let isBSuggestion = b.title.lowercased().contains("günün önerisi") || b.title.lowercased().contains("today's suggestion")
        
        if isASuggestion && !isBSuggestion {
            return true // a (suggestion) comes first
        } else if !isASuggestion && isBSuggestion {
            return false // b (suggestion) comes first
        }
        
        // Then sort by due date if available
        if let ad = a.dueDate, let bd = b.dueDate { return ad > bd } // Latest date first
        if a.dueDate != nil && b.dueDate == nil { return true }
        if a.dueDate == nil && b.dueDate != nil { return false }
        
        // Finally sort by creation date (latest first)
        return a.createdAt > b.createdAt
    }

    private func formattedTitle(for date: Date) -> String {
        let fmt = DateFormatter()
        let language = LanguageManager.shared.currentLanguage == "system" ? 
            Locale.preferredLanguages.first?.components(separatedBy: "-").first ?? "en" : 
            LanguageManager.shared.currentLanguage
        fmt.locale = Locale(identifier: language)
        fmt.dateFormat = "d MMMM yyyy, EEEE"
        return fmt.string(from: date)
    }
}
