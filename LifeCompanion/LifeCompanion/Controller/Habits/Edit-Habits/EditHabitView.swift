//
//  EditHabitView.swift
//  LifeCompanion
//
//  Created by gayeugur on 3.11.2025.
//

import SwiftUI

struct EditHabitView: View {
    @Environment(\.dismiss) private var dismiss
    
    let habit: HabitItem
    @State private var title: String = ""
    @State private var frequency: HabitFrequency = .daily
    @State private var targetCount: Int = 1
    @State private var reminderTime: Date? = nil
    @State private var reminderDates: Set<Date> = []
    @State private var reminderType: ReminderType = .none
    
    @FocusState private var isFieldFocused: Bool

    var onSave: (String, HabitFrequency, Int, Date?, [Date]?) -> Void
    
    enum ReminderType: String, CaseIterable {
        case none = "none"
        case daily = "daily"
        case specificDates = "specificDates"
        
        var displayName: String {
            switch self {
            case .none: return NSLocalizedString("reminder.none", comment: "No Reminder")
            case .daily: return NSLocalizedString("reminder.daily", comment: "Daily")
            case .specificDates: return NSLocalizedString("reminder.specificDates", comment: "Specific Dates")
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Green gradient background matching Habits theme
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
                
                VStack(spacing: 0) {
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Başlık
                        card {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(NSLocalizedString("editHabit.nameLabel", comment: "Habit Name"))
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                TextField(NSLocalizedString("editHabit.namePlaceholder", comment: "Enter habit name"), text: $title)
                                    .focused($isFieldFocused)
                                    .padding(14)
                                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                            }
                        }
                        
                        // Sıklık
                        card {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(NSLocalizedString("editHabit.frequencyLabel", comment: "Frequency"))
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                Picker("", selection: $frequency) {
                                    ForEach(HabitFrequency.allCases, id: \.self) { freq in
                                        Text(freq.displayName).tag(freq)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                        
                        // Hedef
                        card {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(NSLocalizedString("editHabit.targetLabel", comment: "Daily Target"))
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                Stepper("\(frequency.displayName) \(targetCount) \(NSLocalizedString("editHabit.times", comment: "times"))", value: $targetCount, in: 1...50)
                            }
                        }
                        
                        // Hatırlatma
                        card {
                            VStack(alignment: .leading, spacing: 15) {
                                Text(NSLocalizedString("editHabit.reminderLabel", comment: "Reminders"))
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                
                                Picker(NSLocalizedString("reminder.type", comment: "Reminder Type"), selection: $reminderType) {
                                    ForEach(ReminderType.allCases, id: \.self) { type in
                                        Text(type.displayName).tag(type)
                                    }
                                }
                                .pickerStyle(.segmented)
                                
                                if reminderType == .daily {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(NSLocalizedString("reminder.daily.time", comment: "Daily reminder time:"))
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        
                                        DatePicker(
                                            "",
                                            selection: Binding(
                                                get: { reminderTime ?? Date() },
                                                set: { reminderTime = $0 }
                                            ),
                                            displayedComponents: [.hourAndMinute]
                                        )
                                        .labelsHidden()
                                        .datePickerStyle(.compact)
                                    }
                                }
                                
                                if reminderType == .specificDates {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text(NSLocalizedString("reminder.specificDates.select", comment: "Select dates:"))
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                            
                                            Spacer()
                                            
                                            if !reminderDates.isEmpty {
                                                Text("\(reminderDates.count) \(NSLocalizedString("reminder.dates.selected", comment: "dates selected"))")
                                                    .font(.caption)
                                                    .foregroundStyle(.green)
                                            }
                                        }
                                        
                                        // Time selector for specific dates
                                        if !reminderDates.isEmpty {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(NSLocalizedString("reminder.time", comment: "Reminder time:"))
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                
                                                DatePicker(
                                                    "",
                                                    selection: Binding(
                                                        get: { reminderTime ?? Date() },
                                                        set: { reminderTime = $0 }
                                                    ),
                                                    displayedComponents: [.hourAndMinute]
                                                )
                                                .labelsHidden()
                                                .datePickerStyle(.compact)
                                            }
                                        }
                                        
                                        // Date picker
                                        DatePicker(
                                            "",
                                            selection: Binding(
                                                get: { Date() },
                                                set: { newDate in
                                                    let calendar = Calendar.current
                                                    let startOfDay = calendar.startOfDay(for: newDate)
                                                    if reminderDates.contains(startOfDay) {
                                                        reminderDates.remove(startOfDay)
                                                    } else {
                                                        reminderDates.insert(startOfDay)
                                                    }
                                                }
                                            ),
                                            in: Date()...,
                                            displayedComponents: [.date]
                                        )
                                        .datePickerStyle(.graphical)
                                        
                                        // Selected dates list
                                        if !reminderDates.isEmpty {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(NSLocalizedString("reminder.selectedDates", comment: "Selected dates:"))
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                
                                                ForEach(Array(reminderDates.sorted()), id: \.self) { date in
                                                    HStack {
                                                        Text(date, style: .date)
                                                            .font(.caption)
                                                        
                                                        Spacer()
                                                        
                                                        Button {
                                                            reminderDates.remove(date)
                                                        } label: {
                                                            Image(systemName: "xmark.circle.fill")
                                                                .font(.caption)
                                                                .foregroundStyle(.red)
                                                        }
                                                    }
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
                .onTapGesture {
                    isFieldFocused = false
                }
                
                // Güncelle butonu
                Button {
                    let finalReminderTime = (reminderType != .none) ? reminderTime : nil
                    let finalReminderDates = (reminderType == .specificDates && !reminderDates.isEmpty) ? Array(reminderDates) : nil
                    
                    onSave(title.trimmingCharacters(in: .whitespacesAndNewlines),
                           frequency,
                           targetCount,
                           finalReminderTime,
                           finalReminderDates)
                    dismiss()
                } label: {
                    Text(NSLocalizedString("editHabit.updateButton", comment: "Update Habit"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(colors: [
                                Color.blue.opacity(0.85),
                                Color.blue
                            ], startPoint: .top, endPoint: .bottom)
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                        .shadow(color: title.isEmpty ? .clear : Color.blue.opacity(0.4), radius: 16, y: 8)
                }
                .disabled(title.isEmpty)
                .opacity(title.isEmpty ? 0.4 : 1)
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
            .navigationTitle(NSLocalizedString("editHabit.title", comment: "Edit Habit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                
                // klavye done butonu
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { isFieldFocused = false }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                    }
                }
            }
            .onAppear {
                // Mevcut habit verilerini form'a yükle
                title = habit.title
                frequency = habit.frequency
                targetCount = habit.targetCount
                reminderTime = habit.reminderTime
                
                // Set reminder type and dates
                if let dates = habit.reminderDates, !dates.isEmpty {
                    reminderType = .specificDates
                    reminderDates = Set(dates)
                } else if habit.reminderTime != nil {
                    reminderType = .daily
                } else {
                    reminderType = .none
                }
            }
            .onChange(of: reminderType) { oldValue, newValue in
                // Reset reminder data when type changes
                if newValue == .none {
                    reminderTime = nil
                    reminderDates.removeAll()
                } else if newValue != .none && reminderTime == nil {
                    reminderTime = Date()
                }
            }
        }
    }

    @ViewBuilder
    func card<Content: View>(@ViewBuilder _ c: () -> Content) -> some View {
        c()
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.blue.opacity(0.05))
                }
            )
            .shadow(color: .black.opacity(0.05), radius: 14, y: 4)
    }
}