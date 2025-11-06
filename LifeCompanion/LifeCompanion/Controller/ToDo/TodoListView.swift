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
    @Query(sort: \TodoItem.createdAt, order: .forward) private var todos: [TodoItem]
    @StateObject private var viewModel = TodoListViewModel()
    @State private var showingAddHabit = false
    @State private var selectedTodoForHabit: TodoItem?

    var body: some View {
        let counts = viewModel.counts(for: todos)
        let statusCounts = counts.status
        let timeCounts = counts.time
        let sections = viewModel.sections(from: todos)

        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 5) {
                // MARK: - Time Filter Bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(TimeFilter.allCases, id: \.self) { filter in
                            let isSelected = viewModel.timeFilter == filter
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    viewModel.apply(time: filter)
                                }
                            } label: {
                                filterButton(
                                    title: filter.localizedName,
                                    icon: filter.iconName,
                                    count: timeCounts[filter],
                                    tint: filter.tint,
                                    isSelected: isSelected
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                }
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal, 10)

                // MARK: - Status Filter Bar
                HStack(spacing: 6) {
                    ForEach(StatusFilter.allCases, id: \.self) { status in
                        let isSelected = viewModel.statusFilter == status
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                viewModel.apply(status: status)
                            }
                        } label: {
                            filterButton(
                                title: status.localizedName,
                                icon: status.iconName,
                                count: statusCounts[status],
                                tint: status.tint,
                                isSelected: isSelected
                            )
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal, 10)
                .padding(.bottom, 6)
                .lineLimit(1)
                .font(.system(size: 14, weight: .semibold))

                // MARK: - List / Empty
                if sections.isEmpty {
                    emptyStateView
                } else {
                    listView(sections: sections)
                }
            }

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
        .navigationTitle("menu.todos")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $viewModel.showingAddTodo) {
            AddTodoView()
        }
        .navigationDestination(isPresented: $showingAddHabit) {
            if let selectedTodo = selectedTodoForHabit {
                AddHabitView(initialTitle: selectedTodo.title) { title, freq, count, reminder in
                    addHabitFromTodo(title: title, frequency: freq, targetCount: count, reminderTime: reminder)
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

    // MARK: - Filter Button
    private func filterButton(
        title: String,
        icon: String,
        count: Int?,
        tint: Color,
        isSelected: Bool
    ) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(title)
                .font(.system(size: 13))
            if let count, count > 0 {
                Text("\(count)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .font(.system(size: 13, weight: .semibold))
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(isSelected ? tint.opacity(0.15) : Color.white)
        .foregroundColor(isSelected ? tint : .primary)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? tint : Color.gray.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(8)
        .shadow(color: isSelected ? tint.opacity(0.15) : .clear, radius: 3, x: 0, y: 1)
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
                                    Label("Sil", systemImage: "trash")
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
    private func addHabitFromTodo(title: String, frequency: HabitFrequency, targetCount: Int, reminderTime: Date?) {
        let habit = HabitItem(
            title: title,
            frequency: frequency,
            targetCount: targetCount,
            reminderTime: reminderTime
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
            print("Error saving habit from todo: \(error)")
        }
    }
}
