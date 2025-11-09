//
//  GameScore.swift
//  LifeCompanion
//
//  Created on 7.11.2025.
//

import Foundation
import SwiftData

@Model
class GameScore {
    var gridSize: Int
    var moves: Int
    var timeInSeconds: Int
    var score: Int // Calculated score based on time and moves
    var date: Date
    
    init(gridSize: Int, moves: Int, timeInSeconds: Int) {
        self.gridSize = gridSize
        self.moves = moves
        self.timeInSeconds = timeInSeconds
        self.date = Date()
        
        // Calculate score: Higher is better
        // Base score depends on grid difficulty, reduced by time and moves
        let baseScore = gridSize * gridSize * 1000 // Base points
        let timePenalty = timeInSeconds * 2 // 2 points lost per second
        let movePenalty = moves * 10 // 10 points lost per move
        
        self.score = max(100, baseScore - timePenalty - movePenalty) // Minimum 100 points
    }
    
    var timeString: String {
        let minutes = timeInSeconds / 60
        let seconds = timeInSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var gridSizeDescription: String {
        return "\(gridSize)×\(gridSize)"
    }
    
    var difficultyName: String {
        switch gridSize {
        case 3: return "Easy"
        case 4: return "Medium" 
        case 5: return "Hard"
        case 6: return "Expert"
        default: return "Custom"
        }
    }
}