//
//  AddHabitView.swift
//  LifeCompanion
//
//  Created by gayeugur on 30.10.2025.
//

import SwiftUI

struct AddHabitView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var frequency: HabitFrequency = .daily
    @State private var targetCount: Int = 1
    @State private var reminderTime: Date? = nil
    @State private var reminderDates: Set<Date> = []
    @State private var showingSuggestionsSheet: Bool = false
    @State private var reminderType: ReminderType = .none
    
    @FocusState private var isFieldFocused: Bool

    var onSave: (String, HabitFrequency, Int, Date?, [Date]?) -> Void
    
    enum ReminderType: String, CaseIterable {
        case none = "none"
        case daily = "daily"
        case specificDates = "specificDates"
        
        var displayName: String {
            switch self {
            case .none: return "reminder.none".localized
            case .daily: return "reminder.daily".localized
            case .specificDates: return "reminder.specificDates".localized
            }
        }
    }
    var initialTitle: String?
    
    init(initialTitle: String? = nil, onSave: @escaping (String, HabitFrequency, Int, Date?, [Date]?) -> Void) {
        self.initialTitle = initialTitle
        self.onSave = onSave
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
                                HStack {
                                    Text("addHabit.nameLabel".localized)
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                    
                                    Spacer()
                                    
                                    // Öneriler butonu
                                    Button(action: {
                                        showingSuggestionsSheet = true
                                    }) {
                                        HStack(spacing: 5) {
                                            Image(systemName: "lightbulb.fill")
                                                .font(.system(size: 12))
                                            Text("habit.suggestions.button".localized)
                                                .font(.system(size: 12, weight: .semibold))
                                        }
                                        .foregroundColor(.orange)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(.ultraThinMaterial)
                                                .overlay(
                                                    Capsule()
                                                        .stroke(Color.orange.opacity(0.4), lineWidth: 1)
                                                )
                                        )
                                        .shadow(color: Color.orange.opacity(0.2), radius: 2, x: 0, y: 1)
                                    }
                                }
                                
                                TextField("addHabit.namePlaceholder".localized, text: $title)
                                    .focused($isFieldFocused)
                                    .padding(14)
                                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                            }
                        }
                        
                        // Sıklık
                        card {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("addHabit.frequencyLabel".localized)
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
                                Text("addHabit.targetLabel".localized)
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                Stepper("\(frequency.displayName) \(targetCount) \("addHabit.times".localized)", value: $targetCount, in: 1...50)
                            }
                        }
                        
                        // Hatırlatma
                        card {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("addHabit.reminderLabel".localized)
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                
                                Picker("reminder.type".localized, selection: $reminderType) {
                                    ForEach(ReminderType.allCases, id: \.self) { type in
                                        Text(type.displayName).tag(type)
                                    }
                                }
                                .pickerStyle(.segmented)
                                
                                if reminderType == .daily {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("reminder.daily.time".localized)
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
                                            Text("reminder.specificDates.select".localized)
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                            
                                            Spacer()
                                            
                                            if !reminderDates.isEmpty {
                                                Text("\(reminderDates.count) \("reminder.dates.selected".localized)")
                                                    .font(.caption)
                                                    .foregroundStyle(.green)
                                            }
                                        }
                                        
                                        // Time selector for specific dates
                                        if !reminderDates.isEmpty {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("reminder.time".localized)
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
                                                Text("reminder.selectedDates".localized)
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
                
                // Kaydet butonu
                Button {
                    let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmedTitle.isEmpty {
                        let finalReminderTime = (reminderType != .none) ? reminderTime : nil
                        let finalReminderDates = (reminderType == .specificDates && !reminderDates.isEmpty) ? Array(reminderDates) : nil
                        
                        if let dates = finalReminderDates {
                        }
                        
                        onSave(trimmedTitle, frequency, targetCount, finalReminderTime, finalReminderDates)
                        dismiss()
                    }
                } label: {
                    Text("addHabit.saveButton".localized)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(colors: [
                                Color.green.opacity(0.85),
                                Color.green
                            ], startPoint: .top, endPoint: .bottom)
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                        .shadow(color: title.isEmpty ? .clear : Color.green.opacity(0.4), radius: 16, y: 8)
                }
                .disabled(title.isEmpty)
                .opacity(title.isEmpty ? 0.4 : 1)
                .ignoresSafeArea(.keyboard, edges: .bottom)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("addHabit.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                
                // klavye done butonu
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("common.done".localized) { isFieldFocused = false }
                }
            }
            .onAppear {
                if let initialTitle = initialTitle {
                    title = initialTitle
                }
                // Set defaults for todo-based habits
                if initialTitle != nil {
                    frequency = .daily
                    targetCount = 1
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
            .sheet(isPresented: $showingSuggestionsSheet) {
                HabitSuggestionsSheet { template in
                    applyTemplate(template)
                    showingSuggestionsSheet = false
                }
            }
        }
    }

    // MARK: - Template Application
    
    private func applyTemplate(_ template: HabitTemplate) {
        withAnimation(.easeInOut) {
            title = template.title.localized
            frequency = template.frequency
            targetCount = template.targetCount
        }
        // Klavye odağını kaldır
        isFieldFocused = false
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
                        .fill(Color.green.opacity(0.05))
                }
            )
            .shadow(color: .black.opacity(0.05), radius: 14, y: 4)
    }
}
