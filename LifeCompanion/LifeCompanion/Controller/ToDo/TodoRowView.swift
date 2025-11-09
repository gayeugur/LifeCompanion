//
//  TodoRowView.swift
//  LifeCompanion
//
//  Created by gayeugur on 25.10.2025.
//

import SwiftUI

struct TodoRowView: View {
    @Environment(\.modelContext) private var modelContext
    let todo: TodoItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Button(action: toggleCompletion) {
                    Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(todo.isCompleted ? .green : .gray)
                }
                
                VStack(alignment: .leading) {
                    Text(todo.title)
                        .foregroundColor(Color.primaryText)
                        .strikethrough(todo.isCompleted)
                    
                    if let subtitle = todo.notes {
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundColor(Color.secondaryText)
                    }
                }
                
                Spacer()
                
                PriorityBadge(priority: todo.priority)
            }
            
            if let dueDate = todo.dueDate {
                Text("⏰ \(dueDate.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func toggleCompletion() {
        todo.isCompleted.toggle()
        try? modelContext.save()
    }
}
