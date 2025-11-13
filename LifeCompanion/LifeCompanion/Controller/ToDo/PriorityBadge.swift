//
//  PriorityBadge.swift
//  LifeCompanion
//
//  Created by gayeugur on 25.10.2025.
//

import SwiftUI

struct PriorityBadge: View {
    let priority: TodoItem.Priority

    private var localizedText: String {
        switch priority {
        case .low: return "priority.low".localized
        case .medium: return "priority.medium".localized
        case .high: return "priority.high".localized
        }
    }

    var body: some View {
        Text(localizedText)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(priorityColor)
                    .overlay(
                        Capsule()
                            .stroke(Color.borderColor.opacity(0.2), lineWidth: 0.5)
                    )
            )
            .foregroundColor(.white)
    }

    private var priorityColor: Color {
        switch priority {
        case .low: return Color.blue.opacity(0.9)
        case .medium: return Color.warningColor
        case .high: return Color.errorColor
        }
    }
}

#Preview {
    HStack {
        PriorityBadge(priority: .low)
        PriorityBadge(priority: .medium)
        PriorityBadge(priority: .high)
    }
}