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
        case .low: return NSLocalizedString("priority.low", comment: "")
        case .medium: return NSLocalizedString("priority.medium", comment: "")
        case .high: return NSLocalizedString("priority.high", comment: "")
        }
    }

    var body: some View {
        Text(localizedText)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(priorityColor)
            .foregroundColor(.white)
            .clipShape(Capsule())
    }

    private var priorityColor: Color {
        switch priority {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
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