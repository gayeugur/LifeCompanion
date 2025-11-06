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

    @State private var sections: [HistorySection] = []

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            contentView
        }
        .navigationTitle(NSLocalizedString("history.title", comment: "History"))
        .navigationBarTitleDisplayMode(.large)
        .onAppear { loadHistory() }
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
            Text(NSLocalizedString("history.empty", comment: "No history"))
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
        case .daily: return NSLocalizedString("habit.frequency.daily", comment: "Daily")
        case .weekly: return NSLocalizedString("habit.frequency.weekly", comment: "Weekly")
        case .monthly: return NSLocalizedString("habit.frequency.monthly", comment: "Monthly")
        }
    }
}