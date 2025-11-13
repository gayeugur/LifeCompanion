//
//  WorkingMemoryGameView.swift
//  LifeCompanion
//
//  Created on 06.11.2025.
//

import SwiftUI
import SwiftData

struct WorkingMemoryGameView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var feedbackManager: FeedbackManager
    @EnvironmentObject private var languageManager: LanguageManager
    
    // Game settings
    @State private var gridSize: Int = 4
    @State private var gameMode: String = "Single Player"
    
    // Game state
    @State private var cards: [String] = []
    @State private var flippedIndices: Set<Int> = []
    @State private var matchedIndices: Set<Int> = []
    @State private var moves = 0
    @State private var timer = 0
    @State private var gameTimer: Timer?
    @State private var isGameComplete = false
    @State private var showSettings = false
    @State private var showHighScores = false
    
    // Available symbols for cards
    private let symbols = ["🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐻", "🐼", "🐨", "🐯", "🦁", "🐸", "🐵", "🐧", "🐔", "🦆", "🍎", "🍌", "🍊", "🍇", "🍓", "🥝", "🍑", "🥕"]
    
    var body: some View {
        ZStack {
            // Orange gradient background matching Memory Game theme
            LinearGradient(
                colors: [
                    Color.orange.opacity(0.12),
                    Color.orange.opacity(0.06),
                    Color.yellow.opacity(0.04),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                VStack {
                    Text("🧠 Memory Game")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(gameMode)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Game Stats
                HStack(spacing: 40) {
                    VStack {
                        Text("⏱️")
                            .font(.title2)
                        Text("Time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(timeString)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    VStack {
                        Text("👆")
                            .font(.title2)
                        Text("Moves")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(moves)")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    VStack {
                        Text("✅")
                            .font(.title2)
                        Text("Matches")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(matchedIndices.count / 2)")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(.regularMaterial)
                )
                
                // Game Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: gridSize), spacing: 8) {
                    ForEach(0..<cards.count, id: \.self) { index in
                        GameCardView(
                            symbol: cards[index],
                            isFlipped: flippedIndices.contains(index) || matchedIndices.contains(index),
                            isMatched: matchedIndices.contains(index),
                            onTap: { cardTapped(index) }
                        )
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.regularMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 10)
                )
                
                // Game Controls
                HStack(spacing: 12) {
                    Button("New Game") {
                        startNewGame()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Settings") {
                        showSettings = true
                    }
                    .buttonStyle(.bordered)
                    
                    Button("🏆 Scores") {
                        showHighScores = true
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Memory Game")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            gridSize = settingsManager.memoryGameDefaultSize
            startNewGame()
        }
        .sheet(isPresented: $showSettings) {
            GameSettingsSheet(
                gridSize: $gridSize,
                gameMode: $gameMode,
                onApply: {
                    startNewGame()
                    showSettings = false
                }
            )
        }
        .sheet(isPresented: $showHighScores) {
            HighScoresView()
        }
        .alert("🎉 Game Complete!", isPresented: $isGameComplete) {
            Button("New Game") {
                startNewGame()
            }
            Button("View Scores") {
                showHighScores = true
            }
            Button("OK") { }
        } message: {
            let score = calculateScore()
            Text("Congratulations! You completed the game in \(moves) moves and \(timeString).\n\nYour Score: \(score) points")
        }
    }
    
    private var timeString: String {
        let minutes = timer / 60
        let seconds = timer % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func calculateScore() -> Int {
        let baseScore = gridSize * gridSize * 1000 // Base points
        let timePenalty = timer * 2 // 2 points lost per second
        let movePenalty = moves * 10 // 10 points lost per move
        
        return max(100, baseScore - timePenalty - movePenalty) // Minimum 100 points
    }
    
    private func saveScore() {
        let gameScore = GameScore(
            gridSize: gridSize,
            moves: moves,
            timeInSeconds: timer
        )
        modelContext.insert(gameScore)
        
        do {
            try modelContext.save()
        } catch {
        }
    }
    
    private func startNewGame() {
        // Stop timer
        gameTimer?.invalidate()
        
        // Reset game state
        moves = 0
        timer = 0
        flippedIndices.removeAll()
        matchedIndices.removeAll()
        isGameComplete = false
        
        // Create cards based on grid size
        createCards()
        
        // Start timer
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            timer += 1
        }
    }
    
    private func createCards() {
        let totalCards = gridSize * gridSize
        let pairCount = totalCards / 2
        
        var gameCards: [String] = []
        let selectedSymbols = Array(symbols.shuffled().prefix(pairCount))
        
        // Create pairs
        for symbol in selectedSymbols {
            gameCards.append(symbol)
            gameCards.append(symbol)
        }
        
        // Shuffle cards
        cards = gameCards.shuffled()
    }
    
    private func cardTapped(_ index: Int) {
        // Prevent tapping matched cards or if too many cards are flipped
        guard !matchedIndices.contains(index) else { return }
        guard !flippedIndices.contains(index) else { return }
        guard flippedIndices.count < 2 else { return }
        
        // Play card flip feedback
        feedbackManager.cardFlip()
        
        // Flip the card
        flippedIndices.insert(index)
        
        // Check for match when two cards are flipped
        if flippedIndices.count == 2 {
            moves += 1
            checkForMatch()
        }
    }
    
    private func checkForMatch() {
        let indices = Array(flippedIndices)
        let firstCard = cards[indices[0]]
        let secondCard = cards[indices[1]]
        
        if firstCard == secondCard {
            // Match found!
            withAnimation(.spring()) {
                matchedIndices.formUnion(flippedIndices)
                flippedIndices.removeAll()
            }
            
            // Check if game is complete
            if matchedIndices.count == cards.count {
                gameTimer?.invalidate()
                saveScore() // Save the score before showing completion
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isGameComplete = true
                }
            }
        } else {
            // No match - flip back after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut) {
                    flippedIndices.removeAll()
                }
            }
        }
    }
}

struct GameCardView: View {
    let symbol: String
    let isFlipped: Bool
    let isMatched: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(cardBackgroundColor)
                    .stroke(cardBorderColor, lineWidth: 2)
                    .aspectRatio(1, contentMode: .fit)
                
                if isFlipped {
                    Text(symbol)
                        .font(.system(size: cardFontSize))
                        .scaleEffect(isMatched ? 1.1 : 1.0)
                        .animation(.spring(), value: isMatched)
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: cardFontSize * 0.6))
                            .foregroundColor(.blue.opacity(0.7))
                        
                        Text("?")
                            .font(.system(size: cardFontSize * 0.4, weight: .bold))
                            .foregroundColor(.blue.opacity(0.7))
                    }
                }
            }
        }
        .disabled(isFlipped && !isMatched)
        .scaleEffect(isMatched ? 0.95 : 1.0)
        .animation(.spring(), value: isFlipped)
        .animation(.spring(), value: isMatched)
    }
    
    private var cardBackgroundColor: Color {
        if isMatched {
            return .green.opacity(0.6)
        } else if isFlipped {
            return .blue.opacity(0.6)
        } else {
            return .white.opacity(0.9)
        }
    }
    
    private var cardBorderColor: Color {
        if isMatched {
            return .green
        } else if isFlipped {
            return .blue
        } else {
            return .gray.opacity(0.5)
        }
    }
    
    private var cardFontSize: CGFloat {
        return 28
    }
}

struct GameSettingsSheet: View {
    @Binding var gridSize: Int
    @Binding var gameMode: String
    let onApply: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    private let gridSizes = [
        (size: 3, name: "3x3 (Easy)", cards: 9),
        (size: 4, name: "4x4 (Medium)", cards: 16),
        (size: 5, name: "5x5 (Hard)", cards: 25),
        (size: 6, name: "6x6 (Expert)", cards: 36)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("🧠")
                        .font(.system(size: 50))
                    Text("Game Settings")
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Grid Size")
                        .font(.headline)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(gridSizes, id: \.size) { grid in
                            Button(action: {
                                gridSize = grid.size
                                onApply()
                                dismiss()
                            }) {
                                VStack(spacing: 8) {
                                    Text("\(grid.size)×\(grid.size)")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                    
                                    Text(grid.name)
                                        .font(.caption)
                                    
                                    Text("\(grid.cards) cards")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .foregroundColor(gridSize == grid.size ? .white : .primary)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(gridSize == grid.size ? Color.blue : Color.gray.opacity(0.1))
                                )
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}