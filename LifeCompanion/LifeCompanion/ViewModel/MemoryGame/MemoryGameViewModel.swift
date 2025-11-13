//
//  MemoryGameViewModel.swift
//  LifeCompanion
//
//  Created on 06.11.2025.
//

import Foundation
import SwiftUI

@MainActor
final class MemoryGameViewModel: ObservableObject {
    @Published var game: MemoryGame?
    @Published var showingSettings = false
    @Published var showingGameComplete = false
    @Published var selectedGridSize: GridSize = .medium
    @Published var selectedGameMode: GameMode = .singlePlayer
    
    // Game settings from UserDefaults
    @AppStorage("memoryGameGridSize") private var savedGridSize: String = GridSize.medium.rawValue
    @AppStorage("memoryGameMode") private var savedGameMode: String = GameMode.singlePlayer.rawValue
    
    init() {
        loadSettings()
    }
    
    // MARK: - Game Management
    func startNewGame() {
        game = MemoryGame(gridSize: selectedGridSize, gameMode: selectedGameMode)
        game?.startGame()
    }
    
    func pauseGame() {
        game?.pauseGame()
    }
    
    func resumeGame() {
        game?.resumeGame()
    }
    
    func resetGame() {
        game?.resetGame()
    }
    
    func flipCard(_ card: MemoryCard) {
        game?.flipCard(card)
        
        // Check if game is completed
        if game?.gameState == .finished {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.showingGameComplete = true
            }
        }
    }
    
    // MARK: - Settings Management
    func loadSettings() {
        if let gridSize = GridSize(rawValue: savedGridSize) {
            selectedGridSize = gridSize
        }
        
        if let gameMode = GameMode(rawValue: savedGameMode) {
            selectedGameMode = gameMode
        }
    }
    
    func saveSettings() {
        savedGridSize = selectedGridSize.rawValue
        savedGameMode = selectedGameMode.rawValue
    }
    
    func applySettings() {
        saveSettings()
        
        // If there's an active game, ask if user wants to start new game
        if let currentGame = game, currentGame.gameState == .playing {
            // Game is active, we might want to show confirmation dialog
            startNewGame()
        } else {
            // No active game or game is finished, just apply settings
            startNewGame()
        }
    }
    
    // MARK: - Game Statistics
    var currentStats: GameStats? {
        return game?.gameStats
    }
    
    var isGameActive: Bool {
        guard let game = game else { return false }
        return game.gameState == .playing || game.gameState == .paused
    }
    
    var canFlipCards: Bool {
        guard let game = game else { return false }
        return game.gameState == .playing && game.flippedCards.count < 2
    }
    
    // MARK: - Best Scores (Future Enhancement)
    func saveBestScore() {
        guard let stats = currentStats else { return }
        
        let key = "bestScore_\(selectedGridSize.rawValue)_\(selectedGameMode.rawValue)"
        let currentBest = UserDefaults.standard.integer(forKey: key)
        
        // Calculate score based on time and moves (lower is better)
        let score = stats.timeElapsed + (stats.moves * 2)
        
        if currentBest == 0 || score < currentBest {
            UserDefaults.standard.set(score, forKey: key)
        }
    }
    
    func getBestScore() -> Int? {
        let key = "bestScore_\(selectedGridSize.rawValue)_\(selectedGameMode.rawValue)"
        let score = UserDefaults.standard.integer(forKey: key)
        return score > 0 ? score : nil
    }
    
    // MARK: - Animations and Effects
    func cardColor(for card: MemoryCard) -> Color {
        if card.isMatched {
            return .green.opacity(0.6)
        } else if card.isFlipped {
            return .blue.opacity(0.6)
        } else {
            return .white.opacity(0.9)
        }
    }
    
    func cardBorderColor(for card: MemoryCard) -> Color {
        if card.isMatched {
            return .green
        } else if card.isFlipped {
            return .blue
        } else {
            return .gray.opacity(0.5)
        }
    }
}