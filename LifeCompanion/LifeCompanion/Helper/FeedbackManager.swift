//
//  FeedbackManager.swift
//  LifeCompanion
//
//  Created on 7.11.2025.
//

import SwiftUI
import AVFoundation

class FeedbackManager: ObservableObject {
    @AppStorage("soundEffectsEnabled") var soundEffectsEnabled: Bool = true
    @AppStorage("hapticFeedbackEnabled") var hapticFeedbackEnabled: Bool = true
    
    private var audioPlayer: AVAudioPlayer?
    
    // MARK: - Haptic Feedback
    func lightHaptic() {
        guard hapticFeedbackEnabled else { return }
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    func mediumHaptic() {
        guard hapticFeedbackEnabled else { return }
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    func heavyHaptic() {
        guard hapticFeedbackEnabled else { return }
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    func successHaptic() {
        guard hapticFeedbackEnabled else { return }
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    func errorHaptic() {
        guard hapticFeedbackEnabled else { return }
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
    
    func warningHaptic() {
        guard hapticFeedbackEnabled else { return }
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.warning)
    }
    
    // MARK: - Sound Effects
    func playSound(_ soundType: SoundType) {
        guard soundEffectsEnabled else { return }
        
        // Generate system sounds for now - you can add custom sounds later
        switch soundType {
        case .success:
            AudioServicesPlaySystemSound(1519) // Camera shutter success
        case .error:
            AudioServicesPlaySystemSound(1521) // Camera shutter fail
        case .click:
            AudioServicesPlaySystemSound(1104) // Camera shutter click
        case .pop:
            AudioServicesPlaySystemSound(1105) // Camera shutter click
        case .celebration:
            AudioServicesPlaySystemSound(1519) // Success sound
        case .notification:
            AudioServicesPlaySystemSound(1007) // SMS received
        }
    }
    
    // Combined feedback for common actions
    func buttonTap() {
        lightHaptic()
        playSound(.click)
    }
    
    func habitComplete() {
        successHaptic()
        playSound(.success)
    }
    
    func streakCelebration() {
        heavyHaptic()
        playSound(.celebration)
    }
    
    func gameWin() {
        successHaptic()
        playSound(.celebration)
    }
    
    func cardFlip() {
        lightHaptic()
        playSound(.pop)
    }
}

enum SoundType {
    case success
    case error
    case click
    case pop
    case celebration
    case notification
}

// Environment key
struct FeedbackManagerKey: EnvironmentKey {
    static let defaultValue = FeedbackManager()
}

extension EnvironmentValues {
    var feedbackManager: FeedbackManager {
        get { self[FeedbackManagerKey.self] }
        set { self[FeedbackManagerKey.self] = newValue }
    }
}