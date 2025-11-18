//
//  MedicationEntry.swift
//  LifeCompanion
//
//  Created on 03.11.2025.
//

import Foundation
import SwiftData
import UserNotifications

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
        
        // Generate scheduled times for next 7 days
        for dayOffset in 0..<7 {
            guard let dayStart = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            
            switch frequency {
            case .once:
                if let time = calendar.date(byAdding: components, to: dayStart) {
                    scheduledTimes.append(time)
                }
            case .twice:
                // Morning and evening doses
                if let morningTime = calendar.date(byAdding: components, to: dayStart) {
                    scheduledTimes.append(morningTime)
                }
                var eveningComponents = components
                eveningComponents.hour = (eveningComponents.hour ?? 0) + 12
                if let eveningTime = calendar.date(byAdding: eveningComponents, to: dayStart) {
                    scheduledTimes.append(eveningTime)
                }
            case .thrice:
                // Three times a day: morning, noon, evening
                let baseHour = components.hour ?? 8
                let intervals = [0, 6, 12] // 6-hour intervals to ensure all 3 doses fit in 24 hours
                for interval in intervals {
                    var timeComponents = components
                    let targetHour = baseHour + interval
                    // Ensure we don't exceed 23 hours (valid hour range: 0-23)
                    timeComponents.hour = min(targetHour, 23)
                    if let time = calendar.date(byAdding: timeComponents, to: dayStart) {
                        scheduledTimes.append(time)
                    }
                }
            case .twiceWeekly:
                // Twice weekly: Monday and Thursday
                let weekday = calendar.component(.weekday, from: dayStart)
                if weekday == 2 || weekday == 5 { // Monday = 2, Thursday = 5
                    if let time = calendar.date(byAdding: components, to: dayStart) {
                        scheduledTimes.append(time)
                    }
                }
            case .thriceWeekly:
                // Three times weekly: Monday, Wednesday, Friday
                let weekday = calendar.component(.weekday, from: dayStart)
                if weekday == 2 || weekday == 4 || weekday == 6 { // Mon, Wed, Fri
                    if let time = calendar.date(byAdding: components, to: dayStart) {
                        scheduledTimes.append(time)
                    }
                }
            case .asNeeded:
                break
            }
        }
        
        let sortedTimes = scheduledTimes.sorted()
        
        let todayTimes = sortedTimes.filter { calendar.isDateInToday($0) }
        
        return sortedTimes
    }
    
    var completionPercentage: Double {
        guard !scheduledTimes.isEmpty else { 
            return 0 
        }
        let todayScheduled = scheduledTimes.filter { Calendar.current.isDateInToday($0) }
        let todayTaken = takenTimes.filter { Calendar.current.isDateInToday($0) }
        
        guard todayScheduled.count > 0 else { return 0 }
        
        let percentage = Double(todayTaken.count) / Double(todayScheduled.count)
        
        return percentage
    }
    
    var nextDoseTime: Date? {
        guard frequency != .asNeeded else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        
        // First check if there are scheduled times for today that haven't passed
        let todayScheduled = scheduledTimes.filter { calendar.isDateInToday($0) }
        if let nextToday = todayScheduled.first(where: { $0 > now }) {
            return nextToday
        }
        
        // If no more doses today, calculate next dose for tomorrow
        return calculateNextDoseForTomorrow()
    }
    
    private func calculateNextDoseForTomorrow() -> Date? {
        guard let baseTime = scheduledTimes.first else { return nil }
        
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        let tomorrowStart = calendar.startOfDay(for: tomorrow)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: baseTime)
        
        return calendar.date(byAdding: timeComponents, to: tomorrowStart)
    }
    
    // MARK: - Notification Management
    func scheduleNotifications(notificationsEnabled: Bool = true) {
        // Remove existing notifications for this medication
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [self.id.uuidString])
        
        guard self.frequency != .asNeeded else { return }
        
        // Don't schedule if notifications are disabled
        guard notificationsEnabled else { return }
        
        // Schedule notifications for each scheduled time
        for scheduledTime in self.scheduledTimes {
            let content = UNMutableNotificationContent()
            content.title = "medication.notification.title".localized
            content.body = String(format: "medication.notification.body".localized, self.medicationName, self.dosage)
            content.sound = .default
            content.categoryIdentifier = "MEDICATION_REMINDER"
            
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: scheduledTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "\(self.id.uuidString)_\(scheduledTime.timeIntervalSince1970)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if error != nil {
                    // Notification scheduling failed - could log this if needed
                } else {
                    // Notification scheduled successfully
                }
            }
        }
    }
    
    func cancelNotifications() {
        // Remove all notifications for this medication
        let identifiers = self.scheduledTimes.map { "\(self.id.uuidString)_\($0.timeIntervalSince1970)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    func getNotificationIdentifiers() -> [String] {
        return self.scheduledTimes.map { "\(self.id.uuidString)_\($0.timeIntervalSince1970)" }
    }
}

enum MedicationFrequency: String, CaseIterable, Codable {
    case once = "once"
    case twice = "twice"
    case thrice = "thrice"
    case asNeeded = "asNeeded"
    case twiceWeekly = "twiceWeekly"
    case thriceWeekly = "thriceWeekly"
    
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
        case .twiceWeekly:
            return "medication.frequency.twiceWeekly".localized
        case .thriceWeekly:
            return "medication.frequency.thriceWeekly".localized
        }
    }
    
    var timesPerDay: Int {
        switch self {
        case .once: return 1
        case .twice: return 2
        case .thrice: return 3
        case .asNeeded: return 0
        case .twiceWeekly: return 0 // Weekly frequencies don't have daily times
        case .thriceWeekly: return 0
        }
    }
    
    var isWeekly: Bool {
        switch self {
        case .twiceWeekly, .thriceWeekly:
            return true
        default:
            return false
        }
    }
}
