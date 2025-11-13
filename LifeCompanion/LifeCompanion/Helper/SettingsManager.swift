//
//  SettingsManager.swift
//  LifeCompanion
//
//  Created on 7.11.2025.
//

import SwiftUI
import Foundation

class SettingsManager: ObservableObject {
    @AppStorage("selectedLanguage") var selectedLanguage: String = "system" {
        didSet {
            if selectedLanguage != oldValue {
                LanguageManager.shared.currentLanguage = selectedLanguage
                objectWillChange.send()
            }
        }
    }
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = true {
        didSet { objectWillChange.send() }
    }
    @AppStorage("defaultReminderTimeData") var defaultReminderTimeData: Data = Data()
    @AppStorage("dailyWaterGoal") var dailyWaterGoal: Int = 2000 {
        didSet { objectWillChange.send() }
    }
    @AppStorage("streakCelebrationEnabled") var streakCelebrationEnabled: Bool = true {
        didSet { objectWillChange.send() }
    }
    @AppStorage("showStreakInfo") var showStreakInfo: Bool = true {
        didSet { objectWillChange.send() }
    }
    @AppStorage("autoResetTimeData") var autoResetTimeData: Data = Data()
    @AppStorage("memoryGameDefaultSize") var memoryGameDefaultSize: Int = 4 {
        didSet { objectWillChange.send() }
    }
    
    // Computed properties for easy access
    var defaultReminderTime: Date {
        get {
            if let decoded = try? JSONDecoder().decode(Date.self, from: defaultReminderTimeData) {
                return decoded
            }
            // Default to 9:00 AM
            let calendar = Calendar.current
            return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                defaultReminderTimeData = encoded
            }
        }
    }
    
    var autoResetTime: Date {
        get {
            if let decoded = try? JSONDecoder().decode(Date.self, from: autoResetTimeData) {
                return decoded
            }
            // Default to 12:00 AM (midnight)
            let calendar = Calendar.current
            return calendar.date(bySettingHour: 0, minute: 0, second: 0, of: Date()) ?? Date()
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                autoResetTimeData = encoded
            }
        }
    }
    
    // Helper methods
    func getWaterGoalInLiters() -> Double {
        return Double(dailyWaterGoal) / 1000.0
    }
    
    func getGridSizeDescription() -> String {
        return "\(memoryGameDefaultSize)×\(memoryGameDefaultSize)"
    }
    
    func shouldShowStreakCelebration(for streak: Int) -> Bool {
        guard streakCelebrationEnabled else { return false }
        let milestones = [3, 7, 14, 21, 30, 50, 100]
        return milestones.contains(streak)
    }
    
    func getLanguageCode() -> String? {
        return selectedLanguage == "system" ? nil : selectedLanguage
    }
}

// Environment key
struct SettingsManagerKey: EnvironmentKey {
    static let defaultValue = SettingsManager()
}

extension EnvironmentValues {
    var settingsManager: SettingsManager {
        get { self[SettingsManagerKey.self] }
        set { self[SettingsManagerKey.self] = newValue }
    }
}