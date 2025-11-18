//
//  MemoryCard.swift
//  LifeCompanion
//
//  Created on 06.11.2025.
//

import Foundation
import SwiftUI

struct MemoryCard: Identifiable, Equatable {
    let id = UUID()
    let symbol: String
    var isFlipped: Bool = false
    var isMatched: Bool = false
    
    static func == (lhs: MemoryCard, rhs: MemoryCard) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Create pairs of cards for memory game
    static func createDeck(gridSize: GridSize) -> [MemoryCard] {
        let totalCards = gridSize.totalCards
        let pairCount = totalCards / 2
        
        var cards: [MemoryCard] = []
        let symbols = MemoryGameSymbols.getSymbols(count: pairCount)
        
        // Create pairs
        for symbol in symbols {
            cards.append(MemoryCard(symbol: symbol))
            cards.append(MemoryCard(symbol: symbol))
        }
        
        return cards.shuffled()
    }
}

enum GridSize: String, CaseIterable {
    case small = "3x2"    // 6 cards (3 pairs)
    case medium = "3x4"   // 12 cards (6 pairs)
    case large = "4x4"    // 16 cards (8 pairs)
    case extraLarge = "4x5" // 20 cards (10 pairs)
    case huge = "5x6"     // 30 cards (15 pairs)
    
    var rows: Int {
        switch self {
        case .small: return 2
        case .medium: return 3
        case .large: return 4
        case .extraLarge: return 4
        case .huge: return 5
        }
    }
    
    var columns: Int {
        switch self {
        case .small: return 3
        case .medium: return 4
        case .large: return 4
        case .extraLarge: return 5
        case .huge: return 6
        }
    }
    
    var totalCards: Int {
        return rows * columns
    }
    
    var displayName: String {
        switch self {
        case .small: return "memory.grid.small".localized
        case .medium: return "memory.grid.medium".localized
        case .large: return "memory.grid.large".localized
        case .extraLarge: return "memory.grid.extraLarge".localized
        case .huge: return "memory.grid.huge".localized
        }
    }
    
    var difficulty: String {
        switch self {
        case .small: return "memory.difficulty.easy".localized
        case .medium: return "memory.difficulty.medium".localized
        case .large: return "memory.difficulty.hard".localized
        case .extraLarge: return "memory.difficulty.expert".localized
        case .huge: return "memory.difficulty.master".localized
        }
    }
}

enum GameMode: String, CaseIterable {
    case singlePlayer = "singlePlayer"
    case twoPlayer = "twoPlayer"
    
    var displayName: String {
        switch self {
        case .singlePlayer: return "memory.mode.single".localized
        case .twoPlayer: return "memory.mode.two".localized
        }
    }
}

struct MemoryGameSymbols {
    static let allSymbols = [
        // Animals
        "🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐻", "🐼",
        "🐨", "🐯", "🦁", "🐸", "🐵", "🐧", "🐔", "🦆",
        
        // Food
        "🍎", "🍌", "🍊", "🍇", "🍓", "🥝", "🍑", "🥕",
        "🌶️", "🍄", "🥑", "🍅", "🧄", "🧅", "🌽", "🥒",
        
        // Objects
        "⚽", "🏀", "🏈", "⚾", "🎾", "🏐", "🏓", "🏸",
        "🎯", "🎮", "🎲", "🧩", "🎭", "🎪", "🎨", "🎸",
        
        // Nature
        "🌸", "🌺", "🌻", "🌷", "🌹", "🌲", "🌳", "🌴",
        "🍄", "🌕", "⭐", "☀️", "🌈", "❄️", "🔥", "💧"
    ]
    
    static func getSymbols(count: Int) -> [String] {
        return Array(allSymbols.shuffled().prefix(count))
    }
}
