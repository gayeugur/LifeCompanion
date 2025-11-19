//
//  HighScoresView.swift  
//  LifeCompanion
//
//  Created on 7.11.2025.
//

import SwiftUI
import SwiftData

struct HighScoresView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \GameScore.score, order: .reverse) private var allScores: [GameScore]
    
    // Group scores by grid size
    private var scoresByGridSize: [Int: [GameScore]] {
        Dictionary(grouping: allScores, by: { $0.gridSize })
    }
    
    private let gridSizes = [3, 4, 5, 6]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Orange gradient background matching Memory Game theme
                LinearGradient(
                    colors: [
                        Color.orange.opacity(0.08),
                        Color.orange.opacity(0.04),
                        Color.yellow.opacity(0.02),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Text("🏆")
                                .font(.system(size: 50))
                            Text("highScores.title".localized)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            if allScores.isEmpty {
                                Text("highScores.empty.message".localized)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            } else {
                                Text("highScores.subtitle".localized)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 20)
                        
                        if !allScores.isEmpty {
                            // Overall best score
                            if let bestScore = allScores.first {
                                VStack(spacing: 12) {
                                    Text("🌟 " + "highScores.bestOverall".localized)
                                        .font(.headline)
                                        .foregroundColor(.orange)
                                    ScoreCard(score: bestScore, rank: 1, isHighlighted: true)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.orange.opacity(0.1))
                                        .stroke(.orange.opacity(0.3), lineWidth: 1)
                                )
                                .padding(.horizontal)
                            }
                            
                            // Scores by difficulty
                            ForEach(gridSizes, id: \.self) { gridSize in
                                if let scores = scoresByGridSize[gridSize], !scores.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Text(difficultyName(for: gridSize))
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                            
                                            Text("(\(gridSize)×\(gridSize))")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            
                                            Spacer()
                                            
                                            Text(difficultyEmoji(for: gridSize))
                                                .font(.title2)
                                        }
                                        
                                        ForEach(Array(scores.prefix(5).enumerated()), id: \.offset) { index, score in
                                            ScoreCard(score: score, rank: index + 1, isHighlighted: false)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.regularMaterial)
                                    )
                                    .padding(.horizontal)
                                }
                            }
                            
                            // Clear scores button
                            Button("highScores.clearAll".localized) {
                                clearAllScores()
                            }
                            .foregroundColor(.red)
                            .padding()
                        } else {
                            // Empty state with some tips
                            VStack(spacing: 16) {
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 60))
                                    .foregroundColor(.orange.opacity(0.6))
                                Text("highScores.empty.title".localized)
                                    .font(.headline)
                                    .multilineTextAlignment(.center)
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("highScores.tip1".localized)
                                    Text("highScores.tip2".localized)
                                    Text("highScores.tip3".localized)
                                    Text("highScores.tip4".localized)
                                }
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("highScores.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("highScores.done".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func difficultyName(for gridSize: Int) -> String {
        switch gridSize {
        case 3: return "highScores.difficulty.easy".localized
        case 4: return "highScores.difficulty.medium".localized
        case 5: return "highScores.difficulty.hard".localized
        case 6: return "highScores.difficulty.expert".localized
        default: return "highScores.difficulty.custom".localized
        }
    }
    
    private func difficultyEmoji(for gridSize: Int) -> String {
        switch gridSize {
        case 3: return "🟢"
        case 4: return "🟡"
        case 5: return "🟠"
        case 6: return "🔴"
        default: return "⚪"
        }
    }
    
    private func clearAllScores() {
        for score in allScores {
            modelContext.delete(score)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to clear scores: \(error)")
        }
    }
}

// MARK: - Score Card Component
struct ScoreCard: View {
    let score: GameScore
    let rank: Int
    let isHighlighted: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Text("\(rank)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(rankColor)
            }
            
            // Score details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(score.score) " + "highScores.score".localized)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isHighlighted ? .orange : .primary)
                    Spacer()
                    Text(score.difficultyName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(difficultyColor.opacity(0.2))
                        )
                        .foregroundColor(difficultyColor)
                }
                HStack(spacing: 16) {
                    Label(score.timeString, systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Label("\(score.moves) " + "highScores.moves".localized, systemImage: "hand.tap")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(score.date, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isHighlighted ? .orange.opacity(0.1) : .gray.opacity(0.05))
                .stroke(isHighlighted ? .orange.opacity(0.3) : .gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .brown
        default: return .blue
        }
    }
    
    private var difficultyColor: Color {
        switch score.gridSize {
        case 3: return .green
        case 4: return .yellow
        case 5: return .orange
        case 6: return .red
        default: return .gray
        }
    }
}
