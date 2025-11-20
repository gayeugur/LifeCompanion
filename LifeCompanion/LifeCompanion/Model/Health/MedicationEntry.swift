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
    static func generateScheduledTimes(frequency: MedicationFrequency, reminderTime: Date?) -> [Date] {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        var scheduledTimes: [Date] = []
        guard let baseTime = reminderTime else {
            return scheduledTimes
        }
        let baseComponents = calendar.dateComponents([.hour, .minute], from: baseTime)
        for dayOffset in 0..<7 {
            guard let dayStart = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            let weekday = calendar.component(.weekday, from: dayStart)
            switch frequency {
            case .once:
                if let time = calendar.date(byAdding: baseComponents, to: dayStart) {
                    scheduledTimes.append(time)
                }
            case .twice:
                // 2 doz: 08:00 ve 20:00
                let hours = [8, 20]
                for hour in hours {
                    var comps = baseComponents
                    comps.hour = hour
                    if let time = calendar.date(byAdding: comps, to: dayStart) {
                        scheduledTimes.append(time)
                    }
                }
            case .thrice:
                // 3 doz: 08:00, 14:00, 20:00
                let hours = [8, 14, 20]
                for hour in hours {
                    var comps = baseComponents
                    comps.hour = hour
                    if let time = calendar.date(byAdding: comps, to: dayStart) {
                        scheduledTimes.append(time)
                    }
                }
            case .twiceWeekly:
                if weekday == 2 || weekday == 5 {
                    var comps = baseComponents
                    comps.hour = 8
                    if let time = calendar.date(byAdding: comps, to: dayStart) {
                        scheduledTimes.append(time)
                    }
                }
            case .thriceWeekly:
                if weekday == 2 || weekday == 4 || weekday == 6 {
                    var comps = baseComponents
                    comps.hour = 8
                    if let time = calendar.date(byAdding: comps, to: dayStart) {
                        scheduledTimes.append(time)
                    }
                }
            }
        }
        return scheduledTimes
    }
    
    var completionPercentage: Double {
        guard !scheduledTimes.isEmpty else { 
            return 0 
        }
        let calendar = Calendar.current
        let todayScheduled = scheduledTimes.filter { calendar.isDateInToday($0) }
        let todayTaken = takenTimes.filter { calendar.isDateInToday($0) }
        
        // Haftalık ilaçlarda, bugün alınacak doz yoksa %0 göster
        if frequency.isWeekly && todayScheduled.isEmpty {
            return 0
        }
        guard todayScheduled.count > 0 else { return 0 }
        let percentage = Double(todayTaken.count) / Double(todayScheduled.count)
        return percentage
    }
    
    var nextDoseTime: Date? {
        let calendar = Calendar.current
        let now = Date()
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
        guard isActive else { return } // Sadece aktif ilaçlar için
        // Remove existing notifications for this medication
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [self.id.uuidString])
        
        // Don't schedule if notifications are disabled
        guard notificationsEnabled else { return }
        
        // Schedule notifications for each scheduled time
        for scheduledTime in self.scheduledTimes {
            let content = UNMutableNotificationContent()
            content.title = NSLocalizedString("medication.notification.title", comment: "")
            content.body = String(format: NSLocalizedString("medication.notification.body", comment: ""), self.medicationName, self.dosage)
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
    case twiceWeekly = "twiceWeekly"
    case thriceWeekly = "thriceWeekly"
    
    var localizedName: String {
        switch self {
        case .once:
            return NSLocalizedString("medication.frequency.once", comment: "")
        case .twice:
            return NSLocalizedString("medication.frequency.twice", comment: "")
        case .thrice:
            return NSLocalizedString("medication.frequency.thrice", comment: "")
        case .twiceWeekly:
            return NSLocalizedString("medication.frequency.twiceWeekly", comment: "")
        case .thriceWeekly:
            return NSLocalizedString("medication.frequency.thriceWeekly", comment: "")
        }
    }
    
    var timesPerDay: Int {
        switch self {
        case .once: return 1
        case .twice: return 2
        case .thrice: return 3
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
