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
    var onDeleteRequest: () -> Void
    var onEdit: () -> Void
    
    @EnvironmentObject var settingsManager: SettingsManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    // Streak gösterimi
                    if habit.currentStreak > 0 && settingsManager.showStreakInfo {
                        HStack(spacing: 4) {
                            Text(habit.streakEmoji)
                                .font(.caption)
                            Text(habit.streakDescription)
                                .font(.caption)
                                .foregroundColor(.orange)
                                .fontWeight(.medium)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(habit.frequency.displayName.localized)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    // En uzun seri
                    if habit.longestStreak > 0 && settingsManager.showStreakInfo {
                        Text(String(format: "streak.longest".localized, habit.longestStreak))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
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
                        .fontWeight(.medium)
                } else {
                    Button(action: onIncrement) {
                        Text("habit.increment".localized)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.green.opacity(0.85))
                    .scaleEffect(1.0)
                    .animation(.easeInOut(duration: 0.1), value: habit.isCompleted)
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
            Button(role: .destructive) { onDeleteRequest() } label: {
                Label("habit.delete".localized, systemImage: "trash")
            }
            
            Button { onEdit() } label: {
                Label("habit.edit".localized, systemImage: "pencil")
            }
            .tint(.blue)
        }
    }
}
