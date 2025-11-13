//
//  HabitsView.swift
//  LifeCompanion
//
//  Created by gayeugur on 28.10.2025.
//

import SwiftUI
import SwiftData

struct HabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var feedbackManager: FeedbackManager
    @StateObject private var viewModel = HabitListViewModel()
    @State private var showingHistory = false

    
    // Only show today's habits on main screen
    private var todaysHabits: [HabitItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return viewModel.habits.filter { habit in
            // Check if habit has an entry for today
            return habit.entries.contains { entry in
                calendar.isDate(entry.date, inSameDayAs: today)
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Green gradient background matching Habits theme
            LinearGradient(
                colors: [
                    Color.green.opacity(0.12),
                    Color.green.opacity(0.06),
                    Color.mint.opacity(0.04),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if todaysHabits.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "tray.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("habits.empty.title".localized)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                    Text("habits.empty.subtitle".localized)
                        .font(.system(size: 14))
                        .foregroundColor(.gray.opacity(0.7))
                    Spacer()
                }
                .multilineTextAlignment(.center)
                .padding()
            } else {
                List {
                    ForEach(todaysHabits) { habit in
                        HabitRowView(
                            habit: habit,
                            onIncrement: { 
                                // Immediate haptic feedback
                                feedbackManager.buttonTap()
                                
                                let oldStreak = habit.currentStreak
                                viewModel.incrementCount(for: habit, in: modelContext, settingsManager: settingsManager) 
                                
                                // Check for streak milestones (for UI celebration)
                                if habit.isCompleted && habit.currentStreak > oldStreak {
                                    checkStreakMilestone(habit: habit)
                                }
                            },
                            onDeleteRequest: { 
                                feedbackManager.warningHaptic()
                                viewModel.showDeleteConfirmation(for: habit) 
                            },
                            onEdit: { 
                                feedbackManager.lightHaptic()
                                viewModel.startEditing(habit) 
                            }
                        )
                        .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }

            // FAB
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.spring()) {
                            viewModel.showingAddHabit = true
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 58, height: 58)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.customGreen, Color.customGreen.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .shadow(color: Color.customGreen.opacity(0.35), radius: 8, x: 0, y: 4)
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle("habits.title".localized)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            // ...existing code...
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingHistory = true
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .imageScale(.large)
                        .accessibilityLabel(Text("history.title".localized))
                }
            }
        }
        .onAppear {
            viewModel.configure(settingsManager: settingsManager)
            viewModel.fetchHabits(from: modelContext)
            viewModel.checkAutoReset(in: modelContext, settingsManager: settingsManager)
            viewModel.ensureTodayEntries(in: modelContext)
        }
        .sheet(isPresented: $viewModel.showingAddHabit, onDismiss: {
            // Force refresh habits when sheet is dismissed
            viewModel.fetchHabits(from: modelContext)
            viewModel.ensureTodayEntries(in: modelContext)
        }, content: {
            AddHabitView { title, freq, count, reminder, reminderDates in
                viewModel.addHabit(
                    title: title,
                    frequency: freq,
                    targetCount: count,
                    reminderTime: reminder,
                    reminderDates: reminderDates,
                    in: modelContext
                )
            }
        })
        .sheet(isPresented: $viewModel.showingEditHabit, content: {
            if let habit = viewModel.editingHabit {
                EditHabitView(habit: habit) { title, freq, count, reminder, reminderDates in
                    viewModel.updateHabit(
                        habit,
                        title: title,
                        frequency: freq,
                        targetCount: count,
                        reminderTime: reminder,
                        reminderDates: reminderDates,
                        in: modelContext
                    )
                }
            }
        })
        .navigationDestination(isPresented: $showingHistory) {
            HistoryView()
        }
        .confirmationDialog(
            isPresented: $viewModel.showingDeleteConfirmation,
            title: "confirm.delete.habit.title",
            message: "confirm.delete.habit.message",
            confirmButtonTitle: "confirm.delete",
            cancelButtonTitle: "confirm.cancel",
            isDestructive: true,
            confirmAction: {
                viewModel.confirmDelete(in: modelContext)
            }
        )
        
    }
    
    private func checkStreakMilestone(habit: HabitItem) {
        // Streak celebration disabled - just give subtle feedback
        feedbackManager.buttonTap()
    }
}

