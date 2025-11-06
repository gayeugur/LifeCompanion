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
    @State private var showingSuggestionsSheet: Bool = false
    
    @FocusState private var isFieldFocused: Bool

    var onSave: (String, HabitFrequency, Int, Date?) -> Void
    var initialTitle: String?
    
    init(initialTitle: String? = nil, onSave: @escaping (String, HabitFrequency, Int, Date?) -> Void) {
        self.initialTitle = initialTitle
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
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
                                        Text(freq.displayName.localized).tag(freq)
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
                                Stepper("\(frequency.displayName.localized) \(targetCount) \(String(format: "addHabit.times".localized, targetCount))", value: $targetCount, in: 1...50)
                            }
                        }
                        
                        // Hatırlatma
                        card {
                            VStack(alignment: .leading, spacing: 10) {
                                Toggle("addHabit.reminderLabel".localized, isOn: Binding(
                                    get: { reminderTime != nil },
                                    set: { reminderTime = $0 ? Date() : nil }
                                ))
                                
                                if let _ = reminderTime {
                                    DatePicker(
                                        "",
                                        selection: Binding(
                                            get: { reminderTime ?? Date() },
                                            set: { reminderTime = $0 }
                                        ),
                                        displayedComponents: [.hourAndMinute]
                                    )
                                    .labelsHidden()
                                }
                            }
                        }
                    }
                    .padding(20)
                }
                .onTapGesture {                // <— boşluğa tıklayınca klavye kapanır
                    isFieldFocused = false
                }
                
                // Kaydet butonu
                Button {
                    onSave(title.trimmingCharacters(in: .whitespacesAndNewlines),
                           frequency,
                           targetCount,
                           reminderTime)
                    dismiss()
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
            .background(Color(.systemGroupedBackground))
            .navigationTitle("addHabit.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                
                // klavye done butonu
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { isFieldFocused = false }
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
