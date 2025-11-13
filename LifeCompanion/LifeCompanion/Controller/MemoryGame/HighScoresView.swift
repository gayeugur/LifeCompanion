//
//  HighScoresView.swift
//  LifeCompanion
//
//  Created on 7.11.2025.
//

import SwiftUI
import SwiftData

struct HighScoresView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var languageManager: LanguageManager
    @Query(sort: \GameScore.score, order: .reverse) private var allScores: [GameScore]
    
    // Filter scores by grid size
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
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("🏆")
                                .font(.system(size: 50))
                            Text("highScores.title".localized)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Text("highScores.subtitle".localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 20)
                        
                        // Scores by difficulty
                        ForEach(gridSizes, id: \.self) { gridSize in
                            let scores = scoresByGridSize[gridSize] ?? []
                            let topScores = Array(scores.prefix(3)) // Top 3 scores
                            
                            if !topScores.isEmpty {
                                difficultySection(gridSize: gridSize, scores: topScores)
                            }
                        }
                        
                        if allScores.isEmpty {
                            emptyStateView
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
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
    
    @ViewBuilder
    private func difficultySection(gridSize: Int, scores: [GameScore]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                Text(difficultyName(for: gridSize))
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(gridSize)×\(gridSize)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(8)
            }
            
            // Top Scores
            ForEach(Array(scores.enumerated()), id: \.element.date) { index, score in
                scoreRowView(score: score, rank: index + 1)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
    }
    
    @ViewBuilder
    private func scoreRowView(score: GameScore, rank: Int) -> some View {
        HStack(spacing: 12) {
            // Rank
            Text("\(rank)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(rankColor(rank))
                .frame(width: 24)
            
            // Medal for top 3
            Text(medalEmoji(rank))
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("\("highScores.score".localized): \(score.score)")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(score.timeString)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("\(score.moves) \("highScores.moves".localized)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(relativeDateString(score.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Text("🎯")
                .font(.system(size: 60))
            
            Text("highScores.empty.title".localized)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("highScores.empty.message".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
    }
    
    private func difficultyName(for gridSize: Int) -> String {
        switch gridSize {
        case 3: return "highScores.difficulty.easy".localized
        case 4: return "highScores.difficulty.medium".localized
        case 5: return "highScores.difficulty.hard".localized
        case 6: return "highScores.difficulty.expert".localized
        default: return "Custom"
        }
    }
    
    private func medalEmoji(_ rank: Int) -> String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "🏅"
        }
    }
    
    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .brown
        default: return .primary
        }
    }
    
    private func relativeDateString(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}