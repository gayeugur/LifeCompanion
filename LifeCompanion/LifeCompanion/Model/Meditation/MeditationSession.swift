//
//  MeditationSession.swift
//  LifeCompanion
//
//  Created by gayeugur on 17.11.2025.
//

import Foundation
import SwiftUI

struct MeditationSession: Codable, Identifiable {
    let id = UUID()
    let duration: Int // minutes
    let timestamp: Date
    let type: SessionType
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    enum SessionType: String, Codable {
        case timer = "timer"
        case breathing = "breathing"
    }
}


enum AmbientSound: CaseIterable {
    case none, rain, ocean, forest, whitenoise, birds, ambient
    
    var name: String {
        switch self {
        case .none:
            return "meditation.sound.none"
        case .rain:
            return "meditation.sound.rain"
        case .ocean:
            return "meditation.sound.ocean"
        case .forest:
            return "meditation.sound.forest"
        case .whitenoise:
            return "meditation.sound.whitenoise"
        case .birds:
            return "meditation.sound.birds"
        case .ambient:
            return "meditation.sound.ambient"
        }
    }
    
    var icon: String {
        switch self {
        case .none:
            return "speaker.slash"
        case .rain:
            return "cloud.rain.fill"
        case .ocean:
            return "water.waves"
        case .forest:
            return "tree.fill"
        case .whitenoise:
            return "waveform"
        case .birds:
            return "bird.fill"
        case .ambient:
            return "waveform.path.ecg"
        }
    }
    
    var color: Color {
        switch self {
        case .none:
            return .gray
        case .rain:
            return .blue
        case .ocean:
            return .cyan
        case .forest:
            return .green
        case .whitenoise:
            return .purple
        case .birds:
            return .yellow
        case .ambient:
            return .pink
        }
    }
    
    var fileName: String? {
        switch self {
        case .none:
            return nil
        case .rain:
            return "rain_sound" // rain_sound.mp3 dosyası
        case .ocean:
            return "ocean_sound" // ocean_sound.mp3
        case .forest:
            return "forest_sound" // forest_sound.mp3
        case .whitenoise:
            return "whitenoise_sound" // whitenoise_sound.mp3
        case .birds:
            return "birds_sound" // birds_sound.mp3
        case .ambient:
            return "uplifting-pad-texture" // uplifting-pad-texture dosyası
        }
    }
}

enum BreathingPhase {
    case inhale, hold, exhale
    
    var instruction: String {
        switch self {
        case .inhale:
            return "meditation.breathe.in"
        case .hold:
            return "meditation.breathe.hold"
        case .exhale:
            return "meditation.breathe.out"
        }
    }
}

// MARK: - Supporting Enums and Models
enum BreathingTechnique: CaseIterable {
    case fourSevenEight
    case boxBreathing
    case bellyBreathing
    
    var name: String {
        switch self {
        case .fourSevenEight:
            return "meditation.breathing.478"
        case .boxBreathing:
            return "meditation.breathing.box"
        case .bellyBreathing:
            return "meditation.breathing.belly"
        }
    }
    
    var description: String {
        switch self {
        case .fourSevenEight:
            return "meditation.breathing.478.desc"
        case .boxBreathing:
            return "meditation.breathing.box.desc"
        case .bellyBreathing:
            return "meditation.breathing.belly.desc"
        }
    }
    
    var duration: Int {
        switch self {
        case .fourSevenEight:
            return 4
        case .boxBreathing:
            return 4
        case .bellyBreathing:
            return 6
        }
    }
}


