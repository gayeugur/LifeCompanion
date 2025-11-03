//
//  HabitFrequency.swift
//  LifeCompanion
//
//  Created by gayeugur on 1.11.2025.
//

import Foundation
import SwiftUI
import SwiftData

enum HabitFrequency: String, Codable, CaseIterable, Hashable, Identifiable {
    case daily
    case weekly
    case monthly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily: return "addHabit.daily".localized
        case .weekly: return "addHabit.weekly".localized
        case .monthly: return "addHabit.montly".localized
        }
    }
}

extension HabitFrequency {
    var targetText: String {
        switch self {
        case .daily: return "addHabit.daily".localized
        case .weekly: return "addHabit.weekly".localized
        case .monthly: return "addHabit.montly".localized
        }
    }
}

