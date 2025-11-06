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
    var glassCount: Int
    var dailyGoal: Int
    var createdAt: Date
    
    init(date: Date = Date(), glassCount: Int = 0, dailyGoal: Int = 8) {
        self.date = Calendar.current.startOfDay(for: date)
        self.glassCount = glassCount
        self.dailyGoal = dailyGoal
        self.createdAt = Date()
    }
    
    var isGoalReached: Bool {
        return glassCount >= dailyGoal
    }
    
    var progressPercentage: Double {
        return min(Double(glassCount) / Double(dailyGoal), 1.0)
    }
    
    var remainingGlasses: Int {
        return max(dailyGoal - glassCount, 0)
    }
}