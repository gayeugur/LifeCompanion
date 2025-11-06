//
//  MedicationEntry.swift
//  LifeCompanion
//
//  Created on 03.11.2025.
//

import Foundation
import SwiftData

@Model
final class MedicationEntry: Identifiable {
    var id: UUID
    var medicationName: String
    var dosage: String
    var frequency: MedicationFrequency
    var scheduledTimes: [Date]
    var takenTimes: [Date]
    var createdAt: Date
    var isActive: Bool
    
    init(medicationName: String, dosage: String, frequency: MedicationFrequency, scheduledTimes: [Date]) {
        self.id = UUID()
        self.medicationName = medicationName
        self.dosage = dosage
        self.frequency = frequency
        self.scheduledTimes = scheduledTimes
        self.takenTimes = []
        self.createdAt = Date()
        self.isActive = true
    }
    
    // Convenience initializer for adding new medication with reminder time
    convenience init(medicationName: String, dosage: String, frequency: MedicationFrequency, reminderTime: Date? = nil, isActive: Bool = true) {
        let scheduledTimes = Self.generateScheduledTimes(frequency: frequency, reminderTime: reminderTime)
        self.init(medicationName: medicationName, dosage: dosage, frequency: frequency, scheduledTimes: scheduledTimes)
        self.isActive = isActive
    }
    
    // Helper function to generate scheduled times based on frequency
    private static func generateScheduledTimes(frequency: MedicationFrequency, reminderTime: Date?) -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var scheduledTimes: [Date] = []
        
        guard frequency != .asNeeded, let baseTime = reminderTime else {
            return scheduledTimes
        }
        
        let components = calendar.dateComponents([.hour, .minute], from: baseTime)
        
        switch frequency {
        case .once:
            if let time = calendar.date(byAdding: components, to: today) {
                scheduledTimes.append(time)
            }
        case .twice:
            // Morning and evening doses
            if let morningTime = calendar.date(byAdding: components, to: today) {
                scheduledTimes.append(morningTime)
            }
            var eveningComponents = components
            eveningComponents.hour = (eveningComponents.hour ?? 0) + 12
            if let eveningTime = calendar.date(byAdding: eveningComponents, to: today) {
                scheduledTimes.append(eveningTime)
            }
        case .thrice:
            // Three times a day: morning, noon, evening
            let intervals = [0, 8, 16] // 8-hour intervals
            for interval in intervals {
                var timeComponents = components
                timeComponents.hour = (timeComponents.hour ?? 8) + interval
                if let time = calendar.date(byAdding: timeComponents, to: today) {
                    scheduledTimes.append(time)
                }
            }
        case .asNeeded:
            break
        }
        
        return scheduledTimes.sorted()
    }
    
    var completionPercentage: Double {
        guard !scheduledTimes.isEmpty else { return 0 }
        let todayScheduled = scheduledTimes.filter { Calendar.current.isDateInToday($0) }
        let todayTaken = takenTimes.filter { Calendar.current.isDateInToday($0) }
        return Double(todayTaken.count) / Double(todayScheduled.count)
    }
    
    var nextDoseTime: Date? {
        let now = Date()
        return scheduledTimes.first { $0 > now && Calendar.current.isDateInToday($0) }
    }
}

enum MedicationFrequency: String, CaseIterable, Codable {
    case once = "once"
    case twice = "twice"
    case thrice = "thrice"
    case asNeeded = "asNeeded"
    
    var localizedName: String {
        switch self {
        case .once:
            return "medication.frequency.once".localized
        case .twice:
            return "medication.frequency.twice".localized
        case .thrice:
            return "medication.frequency.thrice".localized
        case .asNeeded:
            return "medication.frequency.asNeeded".localized
        }
    }
    
    var timesPerDay: Int {
        switch self {
        case .once: return 1
        case .twice: return 2
        case .thrice: return 3
        case .asNeeded: return 0
        }
    }
}