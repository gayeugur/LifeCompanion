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
    @StateObject private var viewModel = HabitListViewModel()
    @State private var showingHistory = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // app background
                Color(.systemGroupedBackground)
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
                                onIncrement: { viewModel.incrementCount(for: habit, in: modelContext) },
                                onDelete: { viewModel.delete(habit, in: modelContext) }
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
                viewModel.resetIfNeeded(in: modelContext)
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
            .navigationDestination(isPresented: $showingHistory) {
                HistoryView()
            }
        }
    }
}

