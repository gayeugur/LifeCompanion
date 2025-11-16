//
//  MeditationViewModel.swift
//  LifeCompanion
//
//  Created on 03.11.2025.
//

import Foundation
import SwiftUI
import AVFoundation
import UIKit
import UserNotifications

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
    
    // MARK: - Settings
    private var settingsManager: SettingsManager?
    
    func configure(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
    }
    
    // MARK: - Private Properties
    private var timer: Timer?
    private var breathingTimer: Timer?
    private var audioPlayer: AVAudioPlayer?
    private var timerStartTime: Date?
    private var pausedTimeRemaining: Int?
    
    let timerOptions = [5, 10, 15, 20, 30, 45, 60]
    
    // MARK: - Initialization
    init() {
        loadMeditationData()
        timeRemaining = selectedTimer * 60
    }
    
    // MARK: - Timer Functions
    func startTimer() {
        isTimerRunning = true
        timerStartTime = Date()
        pausedTimeRemaining = nil
        
        // Configure audio session for background playback
        configureAudioSessionForBackground()
        
        // Start RunLoop timer for better background performance
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.updateTimerFromBackground()
            }
        }
        
        // Add timer to common run loop modes for better background performance
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    func pauseTimer() {
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
        pausedTimeRemaining = timeRemaining
    }
    
    func stopTimer() {
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
        timeRemaining = selectedTimer * 60
        timerStartTime = nil
        pausedTimeRemaining = nil
        
        // Light haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func updateTimerFromBackground() {
        guard let startTime = timerStartTime, isTimerRunning else { return }
        
        let elapsed = Int(Date().timeIntervalSince(startTime))
        let totalTime = selectedTimer * 60
        let remaining = totalTime - elapsed
        
        if remaining > 0 {
            timeRemaining = remaining
        } else {
            completeTimer()
        }
    }
    
    private func completeTimer() {
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
        
        // Save meditation session
        saveMeditationSession(duration: selectedTimer)
        
        // Reset timer
        timeRemaining = selectedTimer * 60
        timerStartTime = nil
        pausedTimeRemaining = nil
        
        // Strong haptic feedback for completion
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        // Send completion notification
        sendTimerCompletionNotification()
    }
    
    private func configureAudioSessionForBackground() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            // Handle error silently for now
        }
    }
    
    private func sendTimerCompletionNotification() {
        // Don't send notification if notifications are disabled
        guard settingsManager?.notificationsEnabled ?? true else { return }
        
        // Schedule local notification for timer completion
        let content = UNMutableNotificationContent()
        content.title = "meditation.timer.completed.title".localized
        content.body = String(format: "meditation.timer.completed.body".localized, selectedTimer)
        content.sound = .default
        content.categoryIdentifier = "MEDITATION_TIMER"
        
        // Schedule immediate notification
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let identifier = "meditation_timer_completed_\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { _ in
            // Handle silently
        }
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
            print("🔇 No sound selected or filename not found for: \(sound)")
            return
        }
        
        print("🎵 Attempting to play ambient sound: \(sound) with filename: \(fileName)")
        
        // Try to play from bundle first
        if let path = Bundle.main.path(forResource: fileName, ofType: "mp3") {
            print("✅ Found audio file at path: \(path)")
            let url = URL(fileURLWithPath: path)
            playAudioFromURL(url, sound: sound)
        } else {
            print("❌ Audio file not found in bundle for: \(fileName).mp3")
            // Fallback to system sounds for demo
            playSystemSoundForAmbient(sound)
        }
    }
    
    private func playAudioFromURL(_ url: URL, sound: AmbientSound) {
        do {
            print("🎼 Configuring audio session and creating player for: \(sound)")
            
            // Configure audio session
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            // Create and configure player
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // Infinite loop
            audioPlayer?.volume = Float(ambientVolume)
            audioPlayer?.prepareToPlay()
            
            print("🎵 Audio player created successfully, attempting to play...")
            
            // Start playing
            if audioPlayer?.play() == true {
                print("✅ Successfully started playing: \(sound)")
                selectedAmbientSound = sound
                isAmbientSoundPlaying = true
                
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            } else {
                print("❌ Failed to start audio player for: \(sound)")
                playSystemSoundForAmbient(sound)
            }
        } catch {
            print("❌ Error creating audio player for \(sound): \(error.localizedDescription)")
            // Fallback to system sound
            playSystemSoundForAmbient(sound)
        }
    }
    
    private func playSystemSoundForAmbient(_ sound: AmbientSound) {
        print("⚠️ Using system sound fallback for: \(sound) - actual audio file not found or failed to load")
        
        // For demo purposes, we'll simulate playing
        selectedAmbientSound = sound
        isAmbientSoundPlaying = true
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Show message that sound files are needed
        print("💡 Note: This is just a simulation - no actual audio is being played")
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
    
    // MARK: - App State Handling
    func handleAppWillResignActive() {
        // Save current state when app goes to background
        if isTimerRunning {
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "meditation_background_time")
            UserDefaults.standard.set(timeRemaining, forKey: "meditation_time_remaining")
            UserDefaults.standard.set(selectedTimer, forKey: "meditation_selected_timer")
        }
    }
    
    func handleAppDidBecomeActive() {
        // Restore and update timer when app becomes active
        guard isTimerRunning else { return }
        
        let backgroundTime = UserDefaults.standard.double(forKey: "meditation_background_time")
        let savedTimeRemaining = UserDefaults.standard.integer(forKey: "meditation_time_remaining")
        
        if backgroundTime > 0 && savedTimeRemaining > 0 {
            let timeInBackground = Date().timeIntervalSince1970 - backgroundTime
            let newTimeRemaining = savedTimeRemaining - Int(timeInBackground)
            
            if newTimeRemaining > 0 {
                timeRemaining = newTimeRemaining
            } else {
                // Timer completed while in background
                completeTimer()
            }
            
            // Clear saved values
            UserDefaults.standard.removeObject(forKey: "meditation_background_time")
            UserDefaults.standard.removeObject(forKey: "meditation_time_remaining")
            UserDefaults.standard.removeObject(forKey: "meditation_selected_timer")
        }
    }
}
