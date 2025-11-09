//
//  WaterIntake.swift
//  LifeCompanion
//
//  Created by gayeugur on 3.11.2025.
//

import Foundation
import SwiftData

@Model
final class WaterIntake {
    var date: Date
    var dailyGoal: Int // Daily goal in ml
    var amount: Int // Total amount consumed in ml
    var createdAt: Date
    
    init(date: Date = Date(), dailyGoal: Int = 2000, amount: Int = 0) {
        self.date = Calendar.current.startOfDay(for: date)
        self.dailyGoal = dailyGoal // Default 2000ml per day
        self.amount = amount // Total ml consumed
        self.createdAt = Date()
    }
    
    // Computed glass count for backwards compatibility (based on 250ml glasses)
    var glassCount: Int {
        return Int(ceil(Double(amount) / 250.0))
    }
    
    var isGoalReached: Bool {
        return amount >= dailyGoal
    }
    
    var progressPercentage: Double {
        return min(Double(amount) / Double(dailyGoal), 1.0)
    }
    
    var remainingGlasses: Int {
        let glassSize = 250 // Standard glass size in ml
        let remainingMl = max(dailyGoal - amount, 0)
        return Int(ceil(Double(remainingMl) / Double(glassSize)))
    }
    
    // Amount-based properties (primary)
    var totalAmountInMl: Int {
        return amount
    }
    
    var goalAmountInMl: Int {
        return dailyGoal
    }
    
    var remainingAmountInMl: Int {
        return max(dailyGoal - amount, 0)
    }
    
    var amountProgressPercentage: Double {
        return min(Double(amount) / Double(dailyGoal), 1.0)
    }
    
    // Equivalent glasses for display purposes (based on 250ml)
    var equivalentGlasses: Double {
        return Double(amount) / 250.0
    }
}