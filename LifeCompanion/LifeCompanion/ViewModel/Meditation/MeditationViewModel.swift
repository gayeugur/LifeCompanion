//
//  MeditationViewModel.swift
//  LifeCompanion
//
//  Created on 03.11.2025.
//

import Foundation
import SwiftUI
import AVFoundation

@MainActor
final class MeditationViewModel: ObservableObject {
    
    // MARK: - Timer Properties
    @Published var selectedTimer: Int = 10 // minutes
    @Published var isTimerRunning = false
    @Published var timeRemaining: Int = 600 // seconds (10 minutes)
    
    // MARK: - Breathing Exercise Properties
    @Published var selectedBreathingTechnique: BreathingTechnique = .fourSevenEight
    @Published var isBreathingExerciseActive = false
    @Published var breathingPhase: BreathingPhase = .inhale
    @Published var breathingCount = 0
    
    // MARK: - Statistics Properties
    @Published var todayMeditationTime: Int = 0 // minutes
    @Published var weeklyMeditationTime: Int = 0 // minutes
    @Published var currentStreak: Int = 0
    @Published var totalMeditationTime: Int = 0 // minutes
    
    // MARK: - Daily Progress Properties
    @Published var dailyGoal: Int = 15 // minutes
    @Published var todaySessionsCount: Int = 0
    @Published var todaySessions: [MeditationSession] = []
    
    // MARK: - Ambient Sound Properties
    @Published var selectedAmbientSound: AmbientSound = .none
    @Published var isAmbientSoundPlaying = false
    @Published var ambientVolume: Double = 0.5
    
    // MARK: - Private Properties
    private var timer: Timer?
    private var breathingTimer: Timer?
    private var audioPlayer: AVAudioPlayer?
    
    let timerOptions = [5, 10, 15, 20, 30, 45, 60]
    
    // MARK: - Initialization
    init() {
        loadMeditationData()
        timeRemaining = selectedTimer * 60
    }
    
    // MARK: - Timer Functions
    func startTimer() {
        isTimerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.completeTimer()
                }
            }
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    func pauseTimer() {
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    func stopTimer() {
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
        timeRemaining = selectedTimer * 60
        
        // Light haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func completeTimer() {
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
        
        // Save meditation session
        saveMeditationSession(duration: selectedTimer)
        
        // Reset timer
        timeRemaining = selectedTimer * 60
        
        // Strong haptic feedback for completion
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    func selectTimer(_ duration: Int) {
        selectedTimer = duration
        timeRemaining = duration * 60
    }
    
    func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    // MARK: - Breathing Exercise Functions
    func startBreathingExercise() {
        isBreathingExerciseActive = true
        breathingPhase = .inhale
        breathingCount = 0
        
        breathingTimer = Timer.scheduledTimer(withTimeInterval: Double(selectedBreathingTechnique.duration), repeats: true) { _ in
            Task { @MainActor in
                withAnimation {
                    switch self.breathingPhase {
                    case .inhale:
                        self.breathingPhase = .hold
                    case .hold:
                        self.breathingPhase = .exhale
                    case .exhale:
                        self.breathingPhase = .inhale
                        self.breathingCount += 1
                    }
                }
            }
        }
    }
    
    func stopBreathingExercise() {
        isBreathingExerciseActive = false
        breathingTimer?.invalidate()
        breathingTimer = nil
        breathingCount = 0
    }
    
    func selectBreathingTechnique(_ technique: BreathingTechnique) {
        selectedBreathingTechnique = technique
        startBreathingExercise()
    }
    
    // MARK: - Ambient Sound Functions
    func playAmbientSound(_ sound: AmbientSound) {
        // Stop current sound if playing
        stopAmbientSound()
        
        guard sound != .none, let fileName = sound.fileName else {
            return
        }
        
        // Try to play from bundle first
        if let path = Bundle.main.path(forResource: fileName, ofType: "mp3") {
            let url = URL(fileURLWithPath: path)
            playAudioFromURL(url, sound: sound)
        } else {
            // Fallback to system sounds for demo
            playSystemSoundForAmbient(sound)
        }
    }
    
    private func playAudioFromURL(_ url: URL, sound: AmbientSound) {
        do {
            // Configure audio session
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            // Create and configure player
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // Infinite loop
            audioPlayer?.volume = Float(ambientVolume)
            audioPlayer?.prepareToPlay()
            
            // Start playing
            if audioPlayer?.play() == true {
                selectedAmbientSound = sound
                isAmbientSoundPlaying = true
                
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
        } catch {
            print("Audio player error: \(error.localizedDescription)")
            // Fallback to system sound
            playSystemSoundForAmbient(sound)
        }
    }
    
    private func playSystemSoundForAmbient(_ sound: AmbientSound) {
        // For demo purposes, we'll simulate playing
        selectedAmbientSound = sound
        isAmbientSoundPlaying = true
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Show message that sound files are needed
        print("Playing \(sound.name) - Add \(sound.fileName ?? "").mp3 to project for actual audio")
    }
    
    func stopAmbientSound() {
        audioPlayer?.stop()
        audioPlayer = nil
        selectedAmbientSound = .none
        isAmbientSoundPlaying = false
        
        // Reset audio session
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    func updateVolume() {
        audioPlayer?.volume = Float(ambientVolume)
    }
    
    func toggleAmbientSound(_ sound: AmbientSound) {
        if selectedAmbientSound == sound && isAmbientSoundPlaying {
            stopAmbientSound()
        } else {
            playAmbientSound(sound)
        }
    }
    
    // MARK: - Data Management
    func loadMeditationData() {
        let today = getCurrentDateKey()
        
        todayMeditationTime = UserDefaults.standard.integer(forKey: "meditation_today_\(today)")
        weeklyMeditationTime = UserDefaults.standard.integer(forKey: "meditation_weekly")
        currentStreak = UserDefaults.standard.integer(forKey: "meditation_streak")
        totalMeditationTime = UserDefaults.standard.integer(forKey: "meditation_total")
        dailyGoal = UserDefaults.standard.object(forKey: "meditation_daily_goal") as? Int ?? 15
        
        // Load today's sessions
        loadTodaySessions()
    }
    
    private func loadTodaySessions() {
        let today = getCurrentDateKey()
        if let data = UserDefaults.standard.data(forKey: "meditation_sessions_\(today)"),
           let sessions = try? JSONDecoder().decode([MeditationSession].self, from: data) {
            todaySessions = sessions
            todaySessionsCount = sessions.count
        } else {
            todaySessions = []
            todaySessionsCount = 0
        }
    }
    
    private func saveMeditationSession(duration: Int) {
        let today = getCurrentDateKey()
        
        // Create new session
        let newSession = MeditationSession(
            duration: duration,
            timestamp: Date(),
            type: .timer
        )
        
        // Add to today's sessions
        todaySessions.append(newSession)
        todaySessionsCount = todaySessions.count
        
        // Save sessions to UserDefaults
        if let data = try? JSONEncoder().encode(todaySessions) {
            UserDefaults.standard.set(data, forKey: "meditation_sessions_\(today)")
        }
        
        // Update today's meditation time
        todayMeditationTime += duration
        UserDefaults.standard.set(todayMeditationTime, forKey: "meditation_today_\(today)")
        
        // Update total meditation time
        totalMeditationTime += duration
        UserDefaults.standard.set(totalMeditationTime, forKey: "meditation_total")
        
        // Update weekly time
        weeklyMeditationTime += duration
        UserDefaults.standard.set(weeklyMeditationTime, forKey: "meditation_weekly")
        
        // Update streak if first session of the day
        if todaySessionsCount == 1 {
            currentStreak += 1
            UserDefaults.standard.set(currentStreak, forKey: "meditation_streak")
        }
    }
    
    private func getCurrentDateKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    func dayOfWeek(_ index: Int) -> String {
        let days = ["meditation.day.mon", "meditation.day.tue", "meditation.day.wed", 
                   "meditation.day.thu", "meditation.day.fri", "meditation.day.sat", "meditation.day.sun"]
        return days[index].localized
    }
    
    // MARK: - Cleanup
    func cleanup() {
        stopTimer()
        stopBreathingExercise()
        stopAmbientSound()
    }
    
    // MARK: - Goal Management
    func updateDailyGoal(_ newGoal: Int) {
        dailyGoal = newGoal
        UserDefaults.standard.set(dailyGoal, forKey: "meditation_daily_goal")
    }
    
    // MARK: - Manual Session Management
    func addManualSession(duration: Int) {
        saveMeditationSession(duration: duration)
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
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