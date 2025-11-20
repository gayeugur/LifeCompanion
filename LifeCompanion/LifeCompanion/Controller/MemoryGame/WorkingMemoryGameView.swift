//
//  WorkingMemoryGameView.swift
//  LifeCompanion
//
//  Created on 06.11.2025.
//




import SwiftUI
import SwiftData
#if canImport(Helper)
import Helper
#endif

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
    @State private var isViewActive = true
    
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
                    Text("🧠" + "memoryGame.title".localized)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                
                // Game Stats
                HStack(spacing: 40) {
                    VStack {
                        Text("⏱️")
                            .font(.title2)
                        Text("memoryGame.time".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(timeString)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    VStack {
                        Text("👆")
                            .font(.title2)
                        Text("memoryGame.moves".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(moves)")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    VStack {
                        Text("✅")
                            .font(.title2)
                        Text("memoryGame.matches".localized)
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
                ZStack {
                    if gridSize < 6 {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.regularMaterial)
                            .shadow(color: .black.opacity(0.1), radius: 10)
                    }
                    gameGridView
                        .padding()
                }
                
                // Game Controls
                HStack(spacing: 12) {
                    Button("memoryGame.newGame".localized) {
                        startNewGame()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("memoryGame.settings".localized) {
                        showSettings = true
                    }
                    .buttonStyle(.bordered)
                    
                    Button("memoryGame.scores".localized) {
                        showHighScores = true
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("memoryGame.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isViewActive = true
            gridSize = settingsManager.memoryGameDefaultSize
            startNewGame()
        }
        .onDisappear {
            isViewActive = false
            gameTimer?.invalidate()
            gameTimer = nil
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
        .alert("memoryGame.gameComplete".localized, isPresented: $isGameComplete) {
            Button("memory.game.new".localized) {
                startNewGame()
            }
            Button("memoryGame.viewScores".localized) {
                showHighScores = true
            }
            Button("common.ok".localized) { }
        } message: {
            let score = calculateScore()
            Text("memory.game.complete.message".localizedFormat(timeString, "\(moves)", "\(score)"))
        }
    }
    
    private var timeString: String {
        let minutes = timer / 60
        let seconds = timer % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var gameGridView: some View {
        Group {
            if !cards.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: max(1, gridSize)), spacing: 8) {
                    ForEach(cards.indices, id: \.self) { index in
                        if index < cards.count {
                            GameCardView(
                                symbol: cards[index],
                                isFlipped: flippedIndices.contains(index) || matchedIndices.contains(index),
                                isMatched: matchedIndices.contains(index),
                                onTap: { 
                                    if isViewActive {
                                        cardTapped(index) 
                                    }
                                }
                            )
                        }
                    }
                }
            } else {
                ProgressView("Loading game...")
                    .frame(height: 200)
            }
        }
    }
    
    private func calculateScore() -> Int {
        let baseScore = gridSize * gridSize * 1000 // Base points
        let timePenalty = timer * 2 // 2 points lost per second
        let movePenalty = moves * 10 // 10 points lost per move
        
        return max(100, baseScore - timePenalty - movePenalty) // Minimum 100 points
    }
    
    private func saveScore() {
        guard isViewActive else { return }
        
        // Create new GameScore and save to SwiftData
        let gameScore = GameScore(
            gridSize: gridSize,
            moves: moves,
            timeInSeconds: timer
        )
        
        modelContext.insert(gameScore)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save score: \(error)")
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
            guard self.isViewActive else { return }
            DispatchQueue.main.async {
                self.timer += 1
            }
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
        // Safety checks
        guard isViewActive else { return }
        guard index >= 0 && index < cards.count else { return }
        guard !matchedIndices.contains(index) else { return }
        guard !flippedIndices.contains(index) else { return }
        guard flippedIndices.count < 2 else { return }
        
        // Play card flip feedback
        DispatchQueue.main.async {
            self.feedbackManager.cardFlip()
        }
        
        // Flip the card
        flippedIndices.insert(index)
        
        // Check for match when two cards are flipped
        if flippedIndices.count == 2 {
            moves += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.checkForMatch()
            }
        }
    }
    
    private func checkForMatch() {
        guard isViewActive else { return }
        let indices = Array(flippedIndices)
        guard indices.count == 2 else { return }
        guard indices[0] < cards.count && indices[1] < cards.count else { return }
        
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
                gameTimer = nil
                saveScore() // Save the score before showing completion
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    guard self.isViewActive else { return }
                    self.isGameComplete = true
                }
            }
        } else {
            // No match - flip back after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                guard self.isViewActive else { return }
                withAnimation(.easeInOut) {
                    self.flippedIndices.removeAll()
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
                        Spacer(minLength: 0)
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: cardFontSize * 0.6))
                            .foregroundColor(.blue.opacity(0.7))
                        Text("?")
                            .font(.system(size: cardFontSize * 0.4, weight: .bold))
                            .foregroundColor(.blue.opacity(0.7))
                        Spacer(minLength: 0)
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
        (size: 3, name: "memoryGame.easy".localized, icon: "tortoise", cards: 9),
        (size: 4, name: "memoryGame.medium".localized, icon: "hare", cards: 16),
        (size: 5, name: "memoryGame.hard".localized, icon: "bolt", cards: 25),
        (size: 6, name: "memoryGame.expert".localized, icon: "flame", cards: 36)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("🧠")
                        .font(.system(size: 50))
                    Text("memoryGame.gameSettings".localized)
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("memoryGame.gridSize".localized)
                        .font(.headline)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(gridSizes, id: \.size) { grid in
                            Button(action: {
                                gridSize = grid.size
                                onApply()
                                dismiss()
                            }) {
                                VStack(spacing: 4) {
                                    ZStack {
                                        Circle()
                                            .fill(gridSize == grid.size ? Color.blue.opacity(0.8) : Color.gray.opacity(0.12))
                                            .frame(width: 38, height: 38)
                                        Image(systemName: grid.icon)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 22, height: 22)
                                            .foregroundColor(gridSize == grid.size ? .white : .blue)
                                    }
                                    Text("\(grid.size)×\(grid.size)")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    Text(grid.name)
                                        .font(.caption2)
                                    Text(String(format: "memoryGame.cards".localizedFormat(grid.cards)))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .foregroundColor(gridSize == grid.size ? .white : .primary)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 4)
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
            .navigationTitle("memoryGame.settings".localized)
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
}


