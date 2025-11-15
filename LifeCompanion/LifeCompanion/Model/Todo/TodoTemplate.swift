//
//  TodoTemplate.swift
//  LifeCompanion
//
//  Created by gayeugur on 3.11.2025.
//


//For Suggestions Screen
import Foundation
import SwiftUI

struct TodoTemplate: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let icon: String
    let priority: TodoPriority
    let category: TodoCategory
    let hasReminder: Bool
    
    static let suggestions: [TodoTemplate] = [
        // Günlük Görevler
        TodoTemplate(title: "todo.template.buy.groceries", subtitle: "todo.template.buy.groceries.subtitle", icon: "cart.fill", priority: .medium, category: .daily, hasReminder: true),
        TodoTemplate(title: "todo.template.pay.bills", subtitle: "todo.template.pay.bills.subtitle", icon: "creditcard.fill", priority: .high, category: .daily, hasReminder: true),
        TodoTemplate(title: "todo.template.clean.house", subtitle: "todo.template.clean.house.subtitle", icon: "house.fill", priority: .medium, category: .daily, hasReminder: false),
        TodoTemplate(title: "todo.template.walk.dog", subtitle: "todo.template.walk.dog.subtitle", icon: "dog.fill", priority: .medium, category: .daily, hasReminder: true),
        
        // İş Görevleri
        TodoTemplate(title: "todo.template.meeting.prep", subtitle: "todo.template.meeting.prep.subtitle", icon: "person.2.fill", priority: .high, category: .work, hasReminder: true),
        TodoTemplate(title: "todo.template.email.check", subtitle: "todo.template.email.check.subtitle", icon: "envelope.fill", priority: .low, category: .work, hasReminder: false),
        TodoTemplate(title: "todo.template.project.review", subtitle: "todo.template.project.review.subtitle", icon: "doc.text.fill", priority: .high, category: .work, hasReminder: true),
        TodoTemplate(title: "todo.template.call.client", subtitle: "todo.template.call.client.subtitle", icon: "phone.fill", priority: .medium, category: .work, hasReminder: true),
        
        // Kişisel Görevler
        TodoTemplate(title: "todo.template.doctor.appointment", subtitle: "todo.template.doctor.appointment.subtitle", icon: "stethoscope", priority: .high, category: .personal, hasReminder: true),
        TodoTemplate(title: "todo.template.book.vacation", subtitle: "todo.template.book.vacation.subtitle", icon: "airplane", priority: .medium, category: .personal, hasReminder: false),
        TodoTemplate(title: "todo.template.birthday.gift", subtitle: "todo.template.birthday.gift.subtitle", icon: "gift.fill", priority: .medium, category: .personal, hasReminder: true),
        TodoTemplate(title: "todo.template.car.maintenance", subtitle: "todo.template.car.maintenance.subtitle", icon: "car.fill", priority: .medium, category: .personal, hasReminder: true),
        
        // Eğlence & Hobi
        TodoTemplate(title: "todo.template.movie.night", subtitle: "todo.template.movie.night.subtitle", icon: "tv.fill", priority: .low, category: .entertainment, hasReminder: false),
        TodoTemplate(title: "todo.template.gym.session", subtitle: "todo.template.gym.session.subtitle", icon: "dumbbell.fill", priority: .medium, category: .entertainment, hasReminder: true),
        TodoTemplate(title: "todo.template.read.book", subtitle: "todo.template.read.book.subtitle", icon: "book.fill", priority: .low, category: .entertainment, hasReminder: false),
    ]
}

enum TodoCategory: String, CaseIterable {
    case daily = "daily"
    case work = "work"
    case personal = "personal"
    case entertainment = "entertainment"
    
    var localizedName: String {
        switch self {
        case .daily:
            return "todo.category.daily".localized
        case .work:
            return "todo.category.work".localized
        case .personal:
            return "todo.category.personal".localized
        case .entertainment:
            return "todo.category.entertainment".localized
        }
    }
    
    var color: String {
        switch self {
        case .daily: return "blue"
        case .work: return "purple"
        case .personal: return "green"
        case .entertainment: return "orange"
        }
    }
    
    var icon: String {
        switch self {
        case .daily: return "house.fill"
        case .work: return "briefcase.fill"
        case .personal: return "person.fill"
        case .entertainment: return "gamecontroller.fill"
        }
    }
}

enum TodoPriority: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var localizedName: String {
        switch self {
        case .low: return "priority.low".localized
        case .medium: return "priority.medium".localized
        case .high: return "priority.high".localized
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}