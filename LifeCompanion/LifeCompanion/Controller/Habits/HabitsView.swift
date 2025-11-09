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
    @State private var showingStreakCelebration = false
    @State private var celebratingHabit: HabitItem?
    
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

            if viewModel.habits.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "tray.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.5))
                    Text(NSLocalizedString("habits.empty.title", comment: "No habits yet"))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                    Text(NSLocalizedString("habits.empty.subtitle", comment: "Tap + to add a habit"))
                        .font(.system(size: 14))
                        .foregroundColor(.gray.opacity(0.7))
                    Spacer()
                }
                .multilineTextAlignment(.center)
                .padding()
            } else {
                List {
                    ForEach(viewModel.habits) { habit in
                        HabitRowView(
                            habit: habit,
                            onIncrement: { 
                                let oldStreak = habit.currentStreak
                                viewModel.incrementCount(for: habit, in: modelContext) 
                                
                                // Check for streak milestones
                                if habit.isCompleted && habit.currentStreak > oldStreak {
                                    checkStreakMilestone(habit: habit)
                                }
                            },
                            onDeleteRequest: { viewModel.showDeleteConfirmation(for: habit) },
                            onEdit: { viewModel.startEditing(habit) }
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
        .navigationTitle(NSLocalizedString("habits.title", comment: "Habits"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            // ...existing code...
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingHistory = true
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .imageScale(.large)
                        .accessibilityLabel(Text(NSLocalizedString("history.title", comment: "History")))
                }
            }
        }
        .onAppear {
            viewModel.fetchHabits(from: modelContext)
            viewModel.checkAutoReset(in: modelContext, settingsManager: settingsManager)
        }
        .sheet(isPresented: $viewModel.showingAddHabit, content: {
            AddHabitView { title, freq, count, reminder in
                viewModel.addHabit(
                    title: title,
                    frequency: freq,
                    targetCount: count,
                    reminderTime: reminder,
                    in: modelContext
                )
            }
        })
        .sheet(isPresented: $viewModel.showingEditHabit, content: {
            if let habit = viewModel.editingHabit {
                EditHabitView(habit: habit) { title, freq, count, reminder in
                    viewModel.updateHabit(
                        habit,
                        title: title,
                        frequency: freq,
                        targetCount: count,
                        reminderTime: reminder,
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
        .alert("streak.celebration.title".localized, isPresented: $showingStreakCelebration) {
            Button("streak.celebration.button".localized) { }
        } message: {
            if let habit = celebratingHabit {
                Text(String(format: "streak.celebration.message".localized, habit.currentStreak, habit.title, habit.streakEmoji))
            }
        }
    }
    
    private func checkStreakMilestone(habit: HabitItem) {
        // Only celebrate if enabled in settings
        guard settingsManager.shouldShowStreakCelebration(for: habit.currentStreak) else { return }
        
        celebratingHabit = habit
        withAnimation(.spring()) {
            showingStreakCelebration = true
        }
        
        // Use feedback manager for haptic and sound
        feedbackManager.streakCelebration()
        
        // Schedule celebration notification if notifications are enabled
        if settingsManager.notificationsEnabled {
            habit.scheduleStreakCelebrationNotification()
        }
    }
}

