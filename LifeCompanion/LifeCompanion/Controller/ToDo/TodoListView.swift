//
//  TodoListView.swift
//  LifeCompanion
//
//  Created by gayeugur on 25.10.2025.
//

//
//  TodoListView.swift
//  LifeCompanion
//
//  Created by gayeugur on 25.10.2025.
//

import SwiftUI
import SwiftData

struct TodoListView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var feedbackManager: FeedbackManager
    @Query private var allTodos: [TodoItem]
    @StateObject private var viewModel = TodoListViewModel()
    @State private var showingAddHabit = false
    @State private var selectedTodoForHabit: TodoItem?
    
    // Computed property to sort todos by completion status and special rules
    private var todos: [TodoItem] {
        return allTodos.sorted { todo1, todo2 in
            // First, prioritize incomplete tasks
            if todo1.isCompleted != todo2.isCompleted {
                return !todo1.isCompleted && todo2.isCompleted // Incomplete tasks first
            }
            
            // Second, prioritize "günün önerisi" (today's suggestion) at the top
            let isTodo1Suggestion = todo1.title.lowercased().contains("günün önerisi") || todo1.title.lowercased().contains("today's suggestion")
            let isTodo2Suggestion = todo2.title.lowercased().contains("günün önerisi") || todo2.title.lowercased().contains("today's suggestion")
            
            if isTodo1Suggestion && !isTodo2Suggestion {
                return true // todo1 (suggestion) comes first
            } else if !isTodo1Suggestion && isTodo2Suggestion {
                return false // todo2 (suggestion) comes first
            }
            
            // Then sort by createdAt - latest creation date first (today at top, going backwards)
            return todo1.createdAt > todo2.createdAt // Most recently created first
        }
    }

    var body: some View {
        let counts = viewModel.counts(for: todos)
        let statusCounts = counts.status
        let timeCounts = counts.time
        let sections = viewModel.sections(from: todos)

        ZStack {
            // Theme-adaptive blue gradient background
            LinearGradient(
                colors: [
                    Color.primaryBackground,
                    Color.blue.opacity(0.1),
                    Color.secondaryBackground.opacity(0.5),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                // MARK: - Time Filter Bar
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                        Text("todo.filter.time".localized)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(TimeFilter.allCases, id: \.self) { filter in
                                let isSelected = viewModel.timeFilter == filter
                                Button {
                                    feedbackManager.lightHaptic()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        viewModel.apply(time: filter)
                                    }
                                } label: {
                                    modernFilterChip(
                                        title: filter.localizedName,
                                        icon: filter.iconName,
                                        count: timeCounts[filter],
                                        tint: filter.tint,
                                        isSelected: isSelected
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                )
                .padding(.horizontal, 16)

                // MARK: - Status Filter Bar
                VStack(spacing: 4) {
                    HStack {
                        Image(systemName: "list.bullet.circle.fill")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.green)
                        Text("todo.filter.status".localized)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 6)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 3), spacing: 4) {
                        ForEach(StatusFilter.allCases, id: \.self) { status in
                            let isSelected = viewModel.statusFilter == status
                            Button {
                                feedbackManager.lightHaptic()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    viewModel.apply(status: status)
                                }
                            } label: {
                                modernStatusCard(
                                    title: status.localizedName,
                                    icon: status.iconName,
                                    count: statusCounts[status],
                                    tint: status.tint,
                                    isSelected: isSelected
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

                // MARK: - List / Empty
                if sections.isEmpty {
                    emptyStateView
                } else {
                    listView(sections: sections)
                }
            }
            .padding(.top, 8)

            // MARK: - Floating Add Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.spring()) {
                            viewModel.showingAddTodo = true
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [.accentColor, .accentColor.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                            )
                            .shadow(color: .accentColor.opacity(0.3), radius: 6, x: 0, y: 3)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("menu.todos".localized)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.showingAddTodo) {
            AddTodoView()
        }
        .navigationDestination(isPresented: $showingAddHabit) {
            if let selectedTodo = selectedTodoForHabit {
                AddHabitView(initialTitle: selectedTodo.title) { title, freq, count, reminder, reminderDates in
                    addHabitFromTodo(title: title, frequency: freq, targetCount: count, reminderTime: reminder, reminderDates: reminderDates)
                }
            }
        }
        .confirmationDialog(
            isPresented: $viewModel.showingDeleteConfirmation,
            title: "confirm.delete.todo.title",
            message: "confirm.delete.todo.message",
            confirmButtonTitle: "confirm.delete",
            cancelButtonTitle: "confirm.cancel",
            isDestructive: true,
            confirmAction: {
                viewModel.confirmDelete(in: modelContext)
            }
        )
    }

    // MARK: - Modern Filter Chip
    private func modernFilterChip(
        title: String,
        icon: String,
        count: Int?,
        tint: Color,
        isSelected: Bool
    ) -> some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(isSelected ? tint : Color.gray.opacity(0.2))
                    .frame(width: 24, height: 24)
                
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .gray)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? tint : .primary)
                
                if let count, count > 0 {
                    Text("\(count) " + "todo.filter.tasks".localized)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(isSelected ? tint.opacity(0.12) : Color.secondary.opacity(0.06))
                .stroke(isSelected ? tint : Color.secondary.opacity(0.2), lineWidth: isSelected ? 1.0 : 0.8)
        )
        .scaleEffect(isSelected ? 1.0 : 1.0)
        .shadow(
            color: isSelected ? tint.opacity(0.2) : Color.clear,
            radius: isSelected ? 2 : 0,
            x: 0,
            y: isSelected ? 1 : 0
        )
        .clipped()
    }
    
    // MARK: - Modern Status Card
    private func modernStatusCard(
        title: String,
        icon: String,
        count: Int?,
        tint: Color,
        isSelected: Bool
    ) -> some View {
        VStack(spacing: 3) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? tint.opacity(0.15) : Color.gray.opacity(0.05))
                    .frame(width: 22, height: 22)
                
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isSelected ? tint : .gray)
            }
            
            VStack(spacing: 0) {
                Text(title)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(isSelected ? tint : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                if let count, count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(isSelected ? tint : .secondary)
                } else {
                    Text("0")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.gray.opacity(0.5))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? tint.opacity(0.1) : Color.secondary.opacity(0.04))
                .stroke(isSelected ? tint : Color.secondary.opacity(0.15), lineWidth: isSelected ? 1.0 : 0.5)
        )
        .scaleEffect(isSelected ? 1.0 : 1.0)
        .shadow(
            color: isSelected ? tint.opacity(0.15) : Color.clear,
            radius: isSelected ? 3 : 0,
            x: 0,
            y: isSelected ? 1 : 0
        )
        .clipped()
    }

    // MARK: - List View
    private func listView(sections: [TodoSection]) -> some View {
        List {
            ForEach(sections, id: \.id) { section in
                Section(header: headerView(for: section)) {
                    ForEach(section.items) { todo in
                        TodoRowView(todo: todo)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.showDeleteConfirmation(for: todo)
                                } label: {
                                    Label("todo.action.delete".localized, systemImage: "trash")
                                }
                                
                                Button {
                                    selectedTodoForHabit = todo
                                    showingAddHabit = true
                                } label: {
                                    Label("add.habit.swipe".localized, systemImage: "plus.circle")
                                }
                                .tint(.green)
                            }
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    viewModel.toggleCompletion(todo, in: modelContext)
                                }
                            }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "tray.fill")
                .font(.system(size: 55))
                .foregroundColor(.gray.opacity(0.5))
            Text("empty.noTasks")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.gray)
            Text("empty.addTaskPrompt")
                .font(.system(size: 13))
                .foregroundColor(.gray.opacity(0.7))
            Spacer()
        }
        .multilineTextAlignment(.center)
        .padding()
    }

    // MARK: - Section Header
    private func headerView(for section: TodoSection) -> some View {
        HStack {
            Text(section.title)
                .font(.headline)
            Spacer()
            Text("\(section.items.count)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 3)
    }
    
    // MARK: - Add Habit from Todo Function
    private func addHabitFromTodo(title: String, frequency: HabitFrequency, targetCount: Int, reminderTime: Date?, reminderDates: [Date]?) {
        let habit = HabitItem(
            title: title,
            frequency: frequency,
            targetCount: targetCount,
            reminderTime: reminderTime,
            reminderDates: reminderDates
        )
        
        modelContext.insert(habit)
        
        do {
            try modelContext.save()
            
            // Haptic feedback for success
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            // Reset state
            selectedTodoForHabit = nil
            showingAddHabit = false
        } catch {
        }
    }
}
