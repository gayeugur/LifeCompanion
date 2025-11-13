//
//  HistoryView.swift
//  LifeCompanion
//
//  Created by gayeugur on 2.11.2025.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = HabitListViewModel()

    @State private var sections: [HistorySection] = []
    @State private var showingAddHistorySheet = false
    @State private var selectedDate = Date()
    @State private var selectedHabit: HabitItem?
    @State private var allHabits: [HabitItem] = []

    var body: some View {
        ZStack {
            // Green gradient background matching History (part of Habits) theme
            LinearGradient(
                colors: [
                    Color.green.opacity(0.10),
                    Color.green.opacity(0.05),
                    Color.mint.opacity(0.03),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            contentView
        }
        .navigationTitle("history.title".localized)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddHistorySheet = true
                } label: {
                    Image(systemName: "plus")
                        .imageScale(.large)
                }
            }
        }
        .onAppear { 
            loadHistory() 
            loadHabits()
        }
        .sheet(isPresented: $showingAddHistorySheet) {
            AddHistoryEntrySheet(
                habits: allHabits,
                selectedDate: $selectedDate,
                selectedHabit: $selectedHabit
            ) { habit, date, isCompleted in
                viewModel.addHistoryEntry(for: habit, on: date, isCompleted: isCompleted, in: modelContext)
                loadHistory() // Refresh after adding
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if sections.isEmpty {
            emptyState
        } else {
            List {
                ForEach(sections) { section in
                    Section(header: sectionHeader(for: section)) {
                        ForEach(section.entries) { entry in
                            HistoryRowCard(entry: entry)
                                .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
    }

    private func sectionHeader(for section: HistorySection) -> some View {
        HStack {
            Text(Self.headerFormatter.string(from: section.date))
                .font(.headline)
                .foregroundColor(.secondary)
            Spacer()
            Text("\(section.entries.count)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 56))
                .foregroundColor(.gray.opacity(0.5))
            Text("history.empty".localized)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding()
    }

    // MARK: - Data

    private func loadHistory() {
        let descriptor = FetchDescriptor<HabitEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let allEntries = (try? modelContext.fetch(descriptor)) ?? []

        let cal = Calendar.current
        let now = Date()

        // Sadece süresi dolmuş entry'ler
        let expired = allEntries.filter { entry in
            guard let habit = entry.habit else { return false }
            return isExpired(entry: entry, habit: habit, now: now, cal: cal)
        }

        let grouped = Dictionary(grouping: expired) { entry in
            cal.startOfDay(for: entry.date)
        }

        let sortedDates = grouped.keys.sorted(by: >)
        sections = sortedDates.map { date in
            HistorySection(
                id: "\(date.timeIntervalSince1970)",
                date: date,
                entries: grouped[date]!.sorted { ($0.habit?.title ?? "") < ($1.habit?.title ?? "") }
            )
        }
    }

    // Süresi dolmuş mu kontrolü
    private func isExpired(entry: HabitEntry, habit: HabitItem, now: Date, cal: Calendar) -> Bool {
        let entryDay = cal.startOfDay(for: entry.date)

        switch habit.frequency {
        case .daily:
            // entry günü bugünden önce ise dolmuştur
            let today = cal.startOfDay(for: now)
            return entryDay < today

        case .weekly:
            // entry'nin içinde bulunduğu haftanın sonu geçtiyse dolmuştur
            let weekEnd = cal.date(byAdding: .weekOfYear, value: 1, to: entryDay)!
            return weekEnd <= now

        case .monthly:
            // entry'nin içinde bulunduğu ayın sonu geçtiyse dolmuştur
            let monthEnd = cal.date(byAdding: .month, value: 1, to: entryDay)!
            return monthEnd <= now
        }
    }
    
    private func loadHabits() {
        viewModel.fetchHabits(from: modelContext)
        allHabits = viewModel.habits
    }

    private static let headerFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .full
        df.timeStyle = .none
        return df
    }()
}

// MARK: - Section Model

private struct HistorySection: Identifiable {
    let id: String
    let date: Date
    let entries: [HabitEntry]
}

// MARK: - Row

private struct HistoryRowCard: View {
    let entry: HabitEntry

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(entry.isCompleted ? Color.green.opacity(0.9) : Color.red.opacity(0.7))
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.habit?.title ?? "—")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                if let notes = entry.habit?.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                if let freq = entry.habit?.frequency {
                    Text(frequencyTitle(freq))
                        .font(.caption.weight(.semibold))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }

                Image(systemName: entry.isCompleted ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(entry.isCompleted ? .green : .red)
                    .font(.system(size: 18))
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.systemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.primary.opacity(0.18), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
    }

    private func frequencyTitle(_ freq: HabitFrequency) -> String {
        switch freq {
        case .daily: return "habit.frequency.daily".localized
        case .weekly: return "habit.frequency.weekly".localized
        case .monthly: return "habit.frequency.monthly".localized
        }
    }
}

// MARK: - Add History Entry Sheet

struct AddHistoryEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let habits: [HabitItem]
    @Binding var selectedDate: Date
    @Binding var selectedHabit: HabitItem?
    let onSave: (HabitItem, Date, Bool) -> Void
    
    @State private var isCompleted = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Green gradient background
                LinearGradient(
                    colors: [
                        Color.green.opacity(0.08),
                        Color.green.opacity(0.04),
                        Color.mint.opacity(0.02),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Date picker card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("history.add.date".localized)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        
                        DatePicker("", selection: $selectedDate, in: ...Date(), displayedComponents: .date)
                            .datePickerStyle(.compact)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
                    )
                    
                    // Habit picker card  
                    VStack(alignment: .leading, spacing: 12) {
                        Text("history.add.habit".localized)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        
                        Menu {
                            ForEach(habits) { habit in
                                Button(habit.title) {
                                    selectedHabit = habit
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedHabit?.title ?? "history.add.select.habit".localized)
                                    .foregroundColor(selectedHabit == nil ? .secondary : .primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.secondary)
                            }
                            .padding(14)
                            .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
                    )
                    
                    // Status card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("history.add.status".localized)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 16) {
                            Button {
                                isCompleted = true
                            } label: {
                                HStack {
                                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(isCompleted ? .green : .gray)
                                    Text("history.add.completed".localized)
                                        .foregroundColor(.primary)
                                }
                            }
                            
                            Button {
                                isCompleted = false  
                            } label: {
                                HStack {
                                    Image(systemName: !isCompleted ? "xmark.circle.fill" : "circle")
                                        .foregroundColor(!isCompleted ? .red : .gray)
                                    Text("history.add.not.completed".localized)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
                    )
                    
                    Spacer()
                    
                    // Save button
                    Button {
                        guard let habit = selectedHabit else { return }
                        onSave(habit, selectedDate, isCompleted)
                        dismiss()
                    } label: {
                        Text("history.add.save".localized)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(colors: [Color.green.opacity(0.9), Color.green],
                                               startPoint: .top,
                                               endPoint: .bottom)
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: selectedHabit == nil ? .clear : Color.green.opacity(0.3), radius: 8, y: 4)
                    }
                    .disabled(selectedHabit == nil)
                    .opacity(selectedHabit == nil ? 0.5 : 1)
                    .padding(.horizontal, 20)
                }
                .padding(20)
            }
        }
        .navigationTitle("history.add.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }
        }
    }
}