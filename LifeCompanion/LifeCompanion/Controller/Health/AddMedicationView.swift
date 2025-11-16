//
//  AddMedicationView.swift
//  LifeCompanion
//
//  Created on 3.11.2025.
//

import SwiftUI

struct AddMedicationView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Medication details
    @State private var medicationName = ""
    @State private var dosage = ""
    @State private var selectedFrequency: MedicationFrequency = .once
    @State private var reminderTime = Date()
    @State private var isReminderEnabled = true
    
    // Focus state for keyboard management
    @FocusState private var focusedField: Field?
    
    enum Field {
        case medicationName
        case dosage
        case datePicker
    }
    
    // Callback for saving
    let onSave: (MedicationEntry) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Red gradient background matching Health theme
                LinearGradient(
                    colors: [
                        Color.red.opacity(0.08),
                        Color.red.opacity(0.04),
                        Color.pink.opacity(0.02),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .onTapGesture {
                    // Dismiss keyboard when tapping on background
                    focusedField = nil
                }
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Header
                            VStack(spacing: 16) {
                                Image(systemName: "pills.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.red)
                                
                                Text("health.add.medication.title".localized)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("health.add.medication.subtitle".localized)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 20)
                            .padding(.bottom, 10)
                            
                            // Medication Name Card
                            card {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("health.medication.name".localized)
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                    
                                    TextField("health.medication.name.placeholder".localized, text: $medicationName)
                                        .focused($focusedField, equals: .medicationName)
                                        .textContentType(.none)
                                        .autocorrectionDisabled()
                                        .submitLabel(.next)
                                        .onSubmit {
                                            focusedField = .dosage
                                        }
                                        .padding(14)
                                        .background(Color.tertiaryBackground, in: RoundedRectangle(cornerRadius: 16))
                                }
                            }
                            
                            // Dosage Card
                            card {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("health.medication.dosage".localized)
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                    
                                    TextField("health.medication.dosage.placeholder".localized, text: $dosage)
                                        .focused($focusedField, equals: .dosage)
                                        .textContentType(.none)
                                        .autocorrectionDisabled()
                                        .submitLabel(.done)
                                        .onSubmit {
                                            focusedField = nil
                                        }
                                        .padding(14)
                                        .background(Color.tertiaryBackground, in: RoundedRectangle(cornerRadius: 16))
                                }
                            }
                            
                            // Frequency Card
                            card {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("health.medication.frequency".localized)
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                    
                                    VStack(spacing: 8) {
                                        ForEach(MedicationFrequency.allCases, id: \.self) { frequency in
                                            frequencyRow(frequency)
                                        }
                                    }
                                }
                            }
                            
                            // Reminder Card
                            card {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("health.medication.reminder".localized)
                                            .font(.callout)
                                            .foregroundStyle(.secondary)
                                        
                                        Spacer()
                                        
                                        Toggle("", isOn: $isReminderEnabled)
                                    }
                                    
                                    if isReminderEnabled {
                                        DatePicker(
                                            "health.medication.reminder.time".localized,
                                            selection: $reminderTime,
                                            displayedComponents: .hourAndMinute
                                        )
                                        .datePickerStyle(.compact)
                                        .focused($focusedField, equals: .datePicker)
                                    }
                                }
                            }
                            
                            // Save Button
                            Button {
                                saveMedication()
                            } label: {
                                Text("common.save".localized)
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(
                                        LinearGradient(colors: [Color.red.opacity(0.85), Color.red],
                                                       startPoint: .top,
                                                       endPoint: .bottom)
                                    )
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 22))
                                    .shadow(color: isSaveDisabled ? .clear : Color.red.opacity(0.35), radius: 16, y: 8)
                            }
                            .disabled(isSaveDisabled)
                            .opacity(isSaveDisabled ? 0.4 : 1)
                            .padding(.top, 16)
                        }
                        .padding(20)
                    }
                    .onTapGesture {
                        // Dismiss keyboard when tapping on scroll view content
                        focusedField = nil
                    }
                }
            }
        }
        .navigationTitle("health.add.medication.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("common.cancel".localized) {
                    dismiss()
                }
            }
            
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                
                Button("common.done".localized) { 
                    focusedField = nil
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.accentColor)
            }
        }
        .toolbarRole(.editor)
    }
    
    // MARK: - Computed Properties
    private var isSaveDisabled: Bool {
        medicationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
        dosage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Helper Views
    @ViewBuilder
    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.cardBackground)
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.red.opacity(0.03))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.borderColor.opacity(0.1), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }
    
    @ViewBuilder
    private func frequencyRow(_ frequency: MedicationFrequency) -> some View {
        Button(action: {
            selectedFrequency = frequency
        }) {
            HStack(spacing: 12) {
                Image(systemName: selectedFrequency == frequency ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(selectedFrequency == frequency ? .red : .gray)
                    .font(.system(size: 18))
                
                Text(frequency.localizedName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedFrequency == frequency ? Color.red.opacity(0.08) : Color.tertiaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedFrequency == frequency ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Actions
    private func saveMedication() {
        // Trim whitespace from inputs
        let trimmedName = medicationName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDosage = dosage.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty, !trimmedDosage.isEmpty else { return }
        
        let medication = MedicationEntry(
            medicationName: trimmedName,
            dosage: trimmedDosage,
            frequency: selectedFrequency,
            reminderTime: isReminderEnabled ? reminderTime : nil,
            isActive: true
        )
        
        onSave(medication)
        dismiss()
    }
}
