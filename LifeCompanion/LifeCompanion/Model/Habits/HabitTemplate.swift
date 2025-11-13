//
//  HabitTemplate.swift
//  LifeCompanion
//
//  Created by gayeugur on 3.11.2025.
//

import Foundation

struct HabitTemplate: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let icon: String
    let frequency: HabitFrequency
    let targetCount: Int
    let category: HabitCategory
    
    static let suggestions: [HabitTemplate] = [
        // Sağlık
        HabitTemplate(title: "habit.template.drink.water", icon: "drop.fill", frequency: .daily, targetCount: 8, category: .health),
        HabitTemplate(title: "habit.template.brush.teeth", icon: "mouth.fill", frequency: .daily, targetCount: 2, category: .health),
        HabitTemplate(title: "habit.template.exercise", icon: "figure.walk", frequency: .daily, targetCount: 1, category: .health),
        HabitTemplate(title: "habit.template.sleep.early", icon: "bed.double.fill", frequency: .daily, targetCount: 1, category: .health),
        HabitTemplate(title: "habit.template.vitamins", icon: "pills.fill", frequency: .daily, targetCount: 1, category: .health),
        
        // Kişisel Gelişim
        HabitTemplate(title: "habit.template.read.book", icon: "book.fill", frequency: .daily, targetCount: 30, category: .personal),
        HabitTemplate(title: "habit.template.meditation", icon: "leaf.fill", frequency: .daily, targetCount: 1, category: .personal),
        HabitTemplate(title: "habit.template.journal", icon: "note.text", frequency: .daily, targetCount: 1, category: .personal),
        HabitTemplate(title: "habit.template.learn.language", icon: "character.book.closed.fill", frequency: .daily, targetCount: 15, category: .personal),
        
        // Üretkenlik
        HabitTemplate(title: "habit.template.no.social.media", icon: "iphone.slash", frequency: .daily, targetCount: 1, category: .productivity),
        HabitTemplate(title: "habit.template.plan.day", icon: "calendar", frequency: .daily, targetCount: 1, category: .productivity),
        HabitTemplate(title: "habit.template.clean.room", icon: "house.fill", frequency: .weekly, targetCount: 1, category: .productivity),
        
        // Sosyal
        HabitTemplate(title: "habit.template.call.family", icon: "phone.fill", frequency: .weekly, targetCount: 2, category: .social),
        HabitTemplate(title: "habit.template.meet.friends", icon: "person.2.fill", frequency: .weekly, targetCount: 1, category: .social),
    ]
}

enum HabitCategory: String, CaseIterable {
    case health = "health"
    case personal = "personal"
    case productivity = "productivity"
    case social = "social"
    
    var localizedName: String {
        switch self {
        case .health:
            return "habit.category.health".localized
        case .personal:
            return "habit.category.personal".localized
        case .productivity:
            return "habit.category.productivity".localized
        case .social:
            return "habit.category.social".localized
        }
    }
    
    var color: String {
        switch self {
        case .health: return "red"
        case .personal: return "blue"
        case .productivity: return "orange"
        case .social: return "purple"
        }
    }
    
    var icon: String {
        switch self {
        case .health: return "heart.fill"
        case .personal: return "brain.head.profile"
        case .productivity: return "target"
        case .social: return "person.2.fill"
        }
    }
}