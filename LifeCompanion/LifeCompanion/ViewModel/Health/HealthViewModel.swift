//
//  HealthViewModel.swift
//  LifeCompanion
//
//  Created by gayeugur on 3.11.2025.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
final class HealthViewModel: ObservableObject {
    // Settings Manager reference (injected from view)
    private var settingsManager: SettingsManager?
    
    // Water Tracking
    @Published var todayWaterIntake: WaterIntake?
    @Published var weeklyWaterData: [WaterIntake] = []
    
    // Quick Actions
    @Published var coffeeCount: Int = 0
    @Published var walkSteps: Int = 0
    @Published var sleepLogged: Bool = false
    
    // Body Metrics & Goal Calculation
    @Published var height: Double = 170.0 // cm
    @Published var weight: Double = 70.0 // kg
    @Published var useCalculatedGoal: Bool = true
    @Published var manualWaterGoal: Int = 2000 // ml
    
    // Medication Tracking
    @Published var todayMedications: [MedicationEntry] = []
    
    // Constants
    private let stepIncrement = 100
    
    func fetchTodayWaterIntake(from context: ModelContext) {
        do {
            let today = Calendar.current.startOfDay(for: Date())
            
            let predicate = #Predicate<WaterIntake> { intake in
                intake.date == today
            }
            
            let fetchDescriptor = FetchDescriptor<WaterIntake>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            
            let intakes = try context.fetch(fetchDescriptor)
            if let intake = intakes.first {
                todayWaterIntake = intake
            } else {
                // Create new record for today with ml-based defaults
                let defaultGoal = settingsManager?.dailyWaterGoal ?? 2000
                let newIntake = WaterIntake(date: today, dailyGoal: defaultGoal, amount: 0)
                context.insert(newIntake)
                save(context)
                todayWaterIntake = newIntake
            }
        } catch {
            print("❌ Error fetching water intake: \(error)")
            // Fallback - create a safe default
            let today = Calendar.current.startOfDay(for: Date())
            let defaultGoal = settingsManager?.dailyWaterGoal ?? 2000
            let newIntake = WaterIntake(date: today, dailyGoal: defaultGoal, amount: 0)
            todayWaterIntake = newIntake
        }
    }
    
    func addWaterAmount(_ amount: Int = 250, in context: ModelContext) {
        guard let intake = todayWaterIntake else { return }
        intake.amount += amount // Add ml directly
        save(context)
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        print("💧 Added \(amount)ml water. Total: \(intake.amount)ml / \(intake.dailyGoal)ml")
    }
    
    func removeWaterAmount(_ amount: Int = 250, in context: ModelContext) {
        guard let intake = todayWaterIntake, intake.amount > 0 else { return }
        intake.amount = max(0, intake.amount - amount) // Remove ml directly
        save(context)
        
        // Light haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        print("💧 Removed \(amount)ml water. Total: \(intake.amount)ml / \(intake.dailyGoal)ml")
    }
    
    func addCustomWaterAmount(in context: ModelContext, amount: Int) {
        guard let intake = todayWaterIntake else { return }
        intake.amount += amount // Add custom ml amount
        save(context)
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        print("💧 Added \(amount)ml water. Total: \(intake.amount)ml / \(intake.dailyGoal)ml")
    }
    
    func updateDailyGoal(_ newGoalInMl: Int, in context: ModelContext) {
        guard let intake = todayWaterIntake else { return }
        intake.dailyGoal = newGoalInMl // Store goal in ml
        save(context)
        print("💧 Updated daily goal to \(newGoalInMl)ml")
    }
    
    func fetchWeeklyData(from context: ModelContext) {
        let calendar = Calendar.current
        let today = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: today))!
        
        let predicate = #Predicate<WaterIntake> { intake in
            intake.date >= weekAgo
        }
        
        let fetchDescriptor = FetchDescriptor<WaterIntake>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        
        if let intakes = try? context.fetch(fetchDescriptor) {
            weeklyWaterData = intakes
        }
    }
    
    func save(_ context: ModelContext) {
        do {
            try context.save()
            print("✅ Context saved successfully")
        } catch {
            print("❌ Health save error: \(error)")
        }
    }
    
    // MARK: - Motivational Messages
    func getMotivationalMessage() -> (title: String, message: String, emoji: String) {
        guard let intake = todayWaterIntake else {
            return ("health.water.start.title", "health.water.start.message", "💧")
        }
        
        let progress = intake.amountProgressPercentage // Use ml-based progress
        
        switch progress {
        case 0.0:
            return ("health.water.start.title", "health.water.start.message", "💧")
        case 0.0..<0.25:
            return ("health.water.beginning.title", "health.water.beginning.message", "🌱")
        case 0.25..<0.5:
            return ("health.water.quarter.title", "health.water.quarter.message", "🚀")
        case 0.5..<0.75:
            return ("health.water.half.title", "health.water.half.message", "⚡️")
        case 0.75..<1.0:
            return ("health.water.almost.title", "health.water.almost.message", "🔥")
        case 1.0:
            return ("health.water.completed.title", "health.water.completed.message", "🎉")
        default:
            return ("health.water.exceeded.title", "health.water.exceeded.message", "🏆")
        }
    }
    
    // MARK: - Quick Actions
    func loadDailyQuickActions() {
        let today = getCurrentDateKey()
        
        coffeeCount = UserDefaults.standard.integer(forKey: "health_coffee_\(today)")
        walkSteps = UserDefaults.standard.integer(forKey: "health_walk_steps_\(today)")
        sleepLogged = UserDefaults.standard.bool(forKey: "health_sleep_\(today)")
    }
    
    func saveDailyQuickActions() {
        let today = getCurrentDateKey()
        
        UserDefaults.standard.set(coffeeCount, forKey: "health_coffee_\(today)")
        UserDefaults.standard.set(walkSteps, forKey: "health_walk_steps_\(today)")
        UserDefaults.standard.set(sleepLogged, forKey: "health_sleep_\(today)")
    }
    
    func incrementCoffee() {
        coffeeCount += 1
        saveDailyQuickActions()
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    func resetCoffee() {
        coffeeCount = 0
        saveDailyQuickActions()
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    func incrementSteps() {
        walkSteps += stepIncrement
        saveDailyQuickActions()
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    func resetSteps() {
        walkSteps = 0
        saveDailyQuickActions()
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    func toggleSleep() {
        sleepLogged.toggle()
        saveDailyQuickActions()
        
        let impactFeedback = UIImpactFeedbackGenerator(style: sleepLogged ? .medium : .light)
        impactFeedback.impactOccurred()
    }
    
    private func getCurrentDateKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    // MARK: - Body Metrics & Goal Calculation
    var calculatedWaterGoal: Int {
        // Basic calculation: 35ml per kg of body weight
        return max(Int(weight * 35), 1500) // Minimum 1.5L
    }
    
    var currentWaterGoal: Int {
        return useCalculatedGoal ? calculatedWaterGoal : manualWaterGoal
    }
    
    var dailyWaterGoal: Int {
        guard let settingsManager = settingsManager else {
            return currentWaterGoal
        }
        return settingsManager.dailyWaterGoal
    }
    
    var bmi: Double {
        let heightInMeters = height / 100
        return weight / (heightInMeters * heightInMeters)
    }
    
    var bmiCategory: String {
        switch bmi {
        case ..<18.5:
            return "health.bmi.underweight".localized
        case 18.5..<25:
            return "health.bmi.normal".localized
        case 25..<30:
            return "health.bmi.overweight".localized
        default:
            return "health.bmi.obese".localized
        }
    }
    
    func updateBodyMetrics(height: Double, weight: Double, in context: ModelContext) {
        self.height = height
        self.weight = weight
        UserDefaults.standard.set(height, forKey: "health_height")
        UserDefaults.standard.set(weight, forKey: "health_weight")
        
        // Update current water intake goal if exists (ml-based)
        if let todayIntake = todayWaterIntake {
            todayIntake.dailyGoal = dailyWaterGoal // Already in ml
            save(context)
        }
        
        print("💧 Updated body metrics: \(height)cm, \(weight)kg - Water goal: \(dailyWaterGoal)ml")
    }
    
    func toggleGoalType(in context: ModelContext) {
        useCalculatedGoal.toggle()
        UserDefaults.standard.set(useCalculatedGoal, forKey: "health_use_calculated_goal")
        
        // Update current water intake goal if exists (ml-based)
        if let todayIntake = todayWaterIntake {
            todayIntake.dailyGoal = dailyWaterGoal // Already in ml
            save(context)
        }
        
        print("💧 Toggled goal type. Use calculated: \(useCalculatedGoal), Goal: \(dailyWaterGoal)ml")
    }
    
    func updateManualGoal(_ goal: Int) {
        manualWaterGoal = goal
        UserDefaults.standard.set(manualWaterGoal, forKey: "health_manual_goal")
    }
    
    func loadBodyMetrics() {
        height = UserDefaults.standard.double(forKey: "health_height")
        if height == 0 { height = 170.0 }
        
        weight = UserDefaults.standard.double(forKey: "health_weight")
        if weight == 0 { weight = 70.0 }
        
        useCalculatedGoal = UserDefaults.standard.object(forKey: "health_use_calculated_goal") as? Bool ?? true
        manualWaterGoal = UserDefaults.standard.integer(forKey: "health_manual_goal")
        if manualWaterGoal == 0 { manualWaterGoal = 2000 }
    }
    
    // MARK: - Medication Tracking
    func fetchTodayMedications(from context: ModelContext) {
        let predicate = #Predicate<MedicationEntry> { medication in
            medication.isActive
        }
        
        let request = FetchDescriptor<MedicationEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            todayMedications = try context.fetch(request)
            print("💊 Fetched \(todayMedications.count) active medications")
            for med in todayMedications {
                print("💊 - \(med.medicationName): \(med.dosage) (\(med.frequency.localizedName))")
            }
        } catch {
            print("❌ Error fetching medications: \(error)")
            todayMedications = []
        }
    }
    
    func markMedicationTaken(_ medication: MedicationEntry, at time: Date = Date()) {
        medication.takenTimes.append(time)
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    // Settings integration - update water goal from settings (ml-based)
    func updateWaterGoalFromSettings(_ settingsManager: SettingsManager, context: ModelContext) {
        // Use ml goal directly from settings
        let mlGoal = settingsManager.dailyWaterGoal
        
        // Update today's water intake goal
        if let intake = todayWaterIntake {
            intake.dailyGoal = mlGoal // Store goal in ml
            save(context)
        }
        
        // Update manual goal for future use
        manualWaterGoal = mlGoal
        print("💧 Updated water goal from settings: \(mlGoal)ml")
    }
    
    func updateFromSettings(_ settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
        
        // Update current water intake goal if exists and valid (ml-based)
        if let todayIntake = todayWaterIntake, settingsManager.dailyWaterGoal > 0 {
            todayIntake.dailyGoal = settingsManager.dailyWaterGoal // Store goal in ml
        }
        print("💧 Updated from settings: goal = \(settingsManager.dailyWaterGoal)ml")
    }
    
    func checkAutoReset(context: ModelContext) {
        guard let settingsManager = settingsManager else { return }
        
        let now = Date()
        let calendar = Calendar.current
        let autoResetTime = settingsManager.autoResetTime
        
        // Get reset time for today
        let resetComponents = calendar.dateComponents([.hour, .minute], from: autoResetTime)
        guard let todayResetTime = calendar.date(bySettingHour: resetComponents.hour ?? 0,
                                                 minute: resetComponents.minute ?? 0,
                                                 second: 0,
                                                 of: now) else { return }
        
        let lastResetKey = "last_water_reset_date"
        let lastResetString = UserDefaults.standard.string(forKey: lastResetKey) ?? ""
        
        // Create today's date string for comparison
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: now)
        
        // Check if we need to reset (new day and past reset time)
        let needsReset = lastResetString != todayString && now >= todayResetTime
        
        if needsReset {
            resetWaterIntake(context: context)
            UserDefaults.standard.set(todayString, forKey: lastResetKey)
            print("💧 Auto-reset performed at \(dateFormatter.string(from: now))")
        }
    }
    
    func resetWaterIntake(context: ModelContext) {
        guard let intake = todayWaterIntake else { return }
        intake.amount = 0 // Reset ml amount to 0
        save(context)
        print("💧 Water intake reset. Total: 0ml / \(intake.dailyGoal)ml")
    }

}
