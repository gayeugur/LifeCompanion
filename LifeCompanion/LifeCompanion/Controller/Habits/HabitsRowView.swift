//
//  HabitsRowView.swift
//  LifeCompanion
//
//  Created by gayeugur on 30.10.2025.
//

import SwiftUI

struct HabitRowView: View {
    var habit: HabitItem
    var onIncrement: () -> Void
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(habit.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Text(habit.frequency.displayName.localized)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            HStack {
                // Progress bar
                ProgressView(value: Float(habit.currentCount), total: Float(habit.targetCount))
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                    .frame(height: 8)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                
                Spacer()
                
                if habit.isCompleted {
                    Text("habit.completed".localized)
                        .foregroundColor(.green)
                        .font(.subheadline)
                } else {
                    Button("habit.increment".localized) { onIncrement() }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.green.opacity(0.85))

                }
            }
            .font(.subheadline)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.green.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 6, y: 2)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { onDelete() } label: {
                Label("habit.delete".localized, systemImage: "trash")
            }
        }
    }
}
