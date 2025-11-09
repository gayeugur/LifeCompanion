//
//  MemoryGame.swift
//  LifeCompanion
//
//  Created on 06.11.2025.
//

import Foundation

class MemoryGame: ObservableObject {
    @Published var cards: [MemoryCard] = []
    @Published var gameState: GameState = .notStarted
    @Published var currentPlayer: PlayerTurn = .playerOne
    @Published var playerOneScore: Int = 0
    @Published var playerTwoScore: Int = 0
    @Published var moves: Int = 0
    @Published var timeElapsed: Int = 0
    @Published var flippedCards: [MemoryCard] = []
    
    let gridSize: GridSize
    let gameMode: GameMode
    private var timer: Timer?
    private var matchCheckTimer: Timer?
    
    init(gridSize: GridSize, gameMode: GameMode) {
        self.gridSize = gridSize
        self.gameMode = gameMode
        setupGame()
    }
    
    enum GameState {
        case notStarted
        case playing
        case paused
        case finished
    }
    
    enum PlayerTurn {
        case playerOne
        case playerTwo
        
        var displayName: String {
            switch self {
            case .playerOne: return "memory.player.one".localized
            case .playerTwo: return "memory.player.two".localized
            }
        }
    }
    
    // MARK: - Game Setup
    func setupGame() {
        cards = MemoryCard.createDeck(gridSize: gridSize)
        gameState = .notStarted
        currentPlayer = .playerOne
        playerOneScore = 0
        playerTwoScore = 0
        moves = 0
        timeElapsed = 0
        flippedCards = []
    }
    
    func startGame() {
        gameState = .playing
        startTimer()
    }
    
    func pauseGame() {
        gameState = .paused
        timer?.invalidate()
    }
    
    func resumeGame() {
        gameState = .playing
        startTimer()
    }
    
    func resetGame() {
        timer?.invalidate()
        matchCheckTimer?.invalidate()
        setupGame()
    }
    
    // MARK: - Game Timer
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.timeElapsed += 1
        }
    }
    
    // MARK: - Card Logic
    func flipCard(_ card: MemoryCard) {
        print("🃏 Model: flipCard called for \(card.symbol)")
        print("🃏 Game state: \(gameState)")
        print("🃏 Card isFlipped: \(card.isFlipped), isMatched: \(card.isMatched)")
        print("🃏 Flipped cards count: \(flippedCards.count)")
        
        guard gameState == .playing else { 
            print("❌ Game not playing, state: \(gameState)")
            return 
        }
        guard !card.isFlipped && !card.isMatched else { 
            print("❌ Card already flipped or matched")
            return 
        }
        guard flippedCards.count < 2 else { 
            print("❌ Too many cards flipped already")
            return 
        }
        
        // Flip the card
        if let index = cards.firstIndex(where: { $0.id == card.id }) {
            print("✅ Flipping card at index \(index)")
            cards[index].isFlipped = true
            flippedCards.append(cards[index])
        } else {
            print("❌ Card not found in deck")
        }
        
        // Check for match if two cards are flipped
        if flippedCards.count == 2 {
            moves += 1
            checkForMatch()
        }
    }
    
    private func checkForMatch() {
        guard flippedCards.count == 2 else { return }
        
        let card1 = flippedCards[0]
        let card2 = flippedCards[1]
        
        if card1.symbol == card2.symbol {
            // Match found!
            handleMatch()
        } else {
            // No match, flip cards back after delay
            handleNoMatch()
        }
    }
    
    private func handleMatch() {
        // Mark cards as matched
        for flippedCard in flippedCards {
            if let index = cards.firstIndex(where: { $0.id == flippedCard.id }) {
                cards[index].isMatched = true
                cards[index].isShowing = true
            }
        }
        
        // Update score
        if gameMode == .singlePlayer {
            playerOneScore += 10
        } else {
            if currentPlayer == .playerOne {
                playerOneScore += 10
            } else {
                playerTwoScore += 10
            }
            // Player gets another turn for matching
        }
        
        flippedCards.removeAll()
        
        // Check if game is complete
        checkGameCompletion()
    }
    
    private func handleNoMatch() {
        // Switch players in two-player mode
        if gameMode == .twoPlayer {
            switchPlayer()
        }
        
        // Flip cards back after a delay
        matchCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            for flippedCard in self.flippedCards {
                if let index = self.cards.firstIndex(where: { $0.id == flippedCard.id }) {
                    self.cards[index].isFlipped = false
                }
            }
            self.flippedCards.removeAll()
        }
    }
    
    private func switchPlayer() {
        currentPlayer = currentPlayer == .playerOne ? .playerTwo : .playerOne
    }
    
    private func checkGameCompletion() {
        let allMatched = cards.allSatisfy { $0.isMatched }
        
        if allMatched {
            gameState = .finished
            timer?.invalidate()
        }
    }
    
    // MARK: - Game Statistics
    var gameStats: GameStats {
        let totalPairs = gridSize.totalCards / 2
        let matchedPairs = cards.filter { $0.isMatched }.count / 2
        let accuracy = moves > 0 ? Double(matchedPairs) / Double(moves) * 100 : 0
        
        return GameStats(
            moves: moves,
            timeElapsed: timeElapsed,
            accuracy: accuracy,
            matchedPairs: matchedPairs,
            totalPairs: totalPairs
        )
    }
    
    var winner: PlayerTurn? {
        guard gameState == .finished && gameMode == .twoPlayer else { return nil }
        
        if playerOneScore > playerTwoScore {
            return .playerOne
        } else if playerTwoScore > playerOneScore {
            return .playerTwo
        } else {
            return nil // Tie
        }
    }
}

struct GameStats {
    let moves: Int
    let timeElapsed: Int
    let accuracy: Double
    let matchedPairs: Int
    let totalPairs: Int
    
    var formattedTime: String {
        let minutes = timeElapsed / 60
        let seconds = timeElapsed % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var formattedAccuracy: String {
        return String(format: "%.1f%%", accuracy)
    }
}