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
    
    // Callback for saving
    let onSave: (MedicationEntry) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "pills.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    
                    Text("health.add.medication.title".localized)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("health.add.medication.subtitle".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                .padding(.bottom, 30)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Medication Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("health.medication.name".localized)
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            TextField("health.medication.name.placeholder".localized, text: $medicationName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Dosage
                        VStack(alignment: .leading, spacing: 8) {
                            Text("health.medication.dosage".localized)
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            TextField("health.medication.dosage.placeholder".localized, text: $dosage)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Frequency
                        VStack(alignment: .leading, spacing: 12) {
                            Text("health.medication.frequency".localized)
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            VStack(spacing: 8) {
                                ForEach(MedicationFrequency.allCases, id: \.self) { frequency in
                                    frequencyRow(frequency)
                                }
                            }
                        }
                        
                        // Reminder
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("health.medication.reminder".localized)
                                    .font(.headline)
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                Toggle("", isOn: $isReminderEnabled)
                            }
                            
                            if isReminderEnabled {
                                DatePicker(
                                    "health.medication.reminder.time".localized,
                                    selection: $reminderTime,
                                    displayedComponents: .hourAndMinute
                                )
                                .datePickerStyle(WheelDatePickerStyle())
                                .labelsHidden()
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
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
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.save".localized) {
                        saveMedication()
                    }
                    .disabled(medicationName.isEmpty || dosage.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Helper Views
    @ViewBuilder
    private func frequencyRow(_ frequency: MedicationFrequency) -> some View {
        Button(action: {
            selectedFrequency = frequency
        }) {
            HStack {
                Image(systemName: selectedFrequency == frequency ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(selectedFrequency == frequency ? .red : .gray)
                
                Text(frequency.localizedName)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedFrequency == frequency ? Color.red.opacity(0.1) : Color.clear)
            )
        }
    }
    
    // MARK: - Actions
    private func saveMedication() {
        let medication = MedicationEntry(
            medicationName: medicationName,
            dosage: dosage,
            frequency: selectedFrequency,
            reminderTime: isReminderEnabled ? reminderTime : nil,
            isActive: true
        )
        
        onSave(medication)
        dismiss()
    }
}

#Preview {
    AddMedicationView { _ in }
}