//
//  MeditationView.swift
//  LifeCompanion
//
//  Created on 03.11.2025.
//

import SwiftUI

struct MeditationView: View {
    @StateObject private var viewModel = MeditationViewModel()
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var showingGoalAlert = false
    @State private var newGoalText = ""
    
    // Manual session entry
    @State private var showingManualSessionAlert = false
    @State private var manualSessionDuration = ""

    var body: some View {
        NavigationStack {
            ZStack {
                // Theme-adaptive purple gradient background
                LinearGradient(
                    colors: [
                        Color.primaryBackground,
                        Color.purple.opacity(0.1),
                        Color.secondaryBackground.opacity(0.6),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                    // Header Stats
                    statsCard
                    
                    // Daily Progress
                    dailyProgressCard
                    
                    // Timer Section
                    timerCard
                    
                    // Breathing Exercises
                    breathingExercisesCard
                    
                    // Ambient Sounds
                    ambientSoundsCard
                    
                    // Progress Tracking
                    progressCard
                }
                .padding()
                }
                
                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showManualSessionEntry()
                        }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.purple, Color.indigo],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                                .shadow(
                                    color: Color.black.opacity(0.15),
                                    radius: 12,
                                    x: 0,
                                    y: 6
                                )
                                .scaleEffect(1.0)
                        }
                        .buttonStyle(FloatingButtonStyle())
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("menu.meditation".localized)
            .navigationBarTitleDisplayMode(.large)
            .onDisappear {
                viewModel.cleanup()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                viewModel.handleAppWillResignActive()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                viewModel.handleAppDidBecomeActive()
            }
            .alert("meditation.goal.alert.title".localized, isPresented: $showingGoalAlert) {
                TextField("meditation.goal.alert.placeholder".localized, text: $newGoalText)
                    .keyboardType(.numberPad)
                Button("Cancel", role: .cancel) { }
                Button("Save") {
                    if let newGoal = Int(newGoalText), newGoal > 0 {
                        viewModel.updateDailyGoal(newGoal)
                    }
                }
            } message: {
                Text("meditation.goal.alert.message".localized)
            }
            .alert("meditation.add.session.title".localized, isPresented: $showingManualSessionAlert) {
                TextField("meditation.add.session.placeholder".localized, text: $manualSessionDuration)
                    .keyboardType(.numberPad)
                Button("common.cancel".localized, role: .cancel) { }
                Button("common.save".localized) {
                    if let duration = Int(manualSessionDuration), duration > 0 {
                        viewModel.addManualSession(duration: duration)
                        manualSessionDuration = ""
                    }
                }
            } message: {
                Text("meditation.add.session.message".localized)
            }
        }
        .onAppear {
            viewModel.configure(settingsManager: settingsManager)
        }
    }
    
    // MARK: - Stats Card
    @ViewBuilder
    private var statsCard: some View {
        HStack(spacing: 16) {
            statItem(
                title: "meditation.today".localized,
                value: "\(viewModel.todayMeditationTime)",
                unit: "meditation.minutes".localized,
                color: .purple,
                icon: "clock.fill"
            )
            
            statItem(
                title: "meditation.streak".localized,
                value: "\(viewModel.currentStreak)",
                unit: "meditation.days".localized,
                color: .orange,
                icon: "flame.fill"
            )
            
            statItem(
                title: "meditation.total".localized,
                value: "\(viewModel.totalMeditationTime)",
                unit: "meditation.minutes".localized,
                color: .blue,
                icon: "heart.fill"
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Daily Progress Card
    @ViewBuilder
    private var dailyProgressCard: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "target")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text("meditation.daily.progress".localized)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    newGoalText = "\(viewModel.dailyGoal)"
                    showingGoalAlert = true
                }) {
                    Text("meditation.goal".localized + ": \(viewModel.dailyGoal)m")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.green.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
            }
            
            // Progress Bar
            VStack(spacing: 8) {
                HStack {
                    Text("meditation.progress.today".localized)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(viewModel.todayMeditationTime) / \(viewModel.dailyGoal) \("meditation.minutes".localized)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 12)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: viewModel.todayMeditationTime >= viewModel.dailyGoal 
                                        ? [.green, .mint] 
                                        : [.purple, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: geometry.size.width * min(1.0, Double(viewModel.todayMeditationTime) / Double(viewModel.dailyGoal)),
                                height: 12
                            )
                            .animation(.easeInOut(duration: 0.5), value: viewModel.todayMeditationTime)
                    }
                }
                .frame(height: 12)
            }
            
            // Today's Sessions
            if !viewModel.todaySessions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("meditation.sessions.today".localized)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("\(viewModel.todaySessions.count) \("meditation.sessions".localized)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Session timeline
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.todaySessions.indices, id: \.self) { index in
                                sessionBubble(session: viewModel.todaySessions[index])
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
            } else {
                HStack {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.title3)
                        .foregroundColor(.gray)
                    
                    Text("meditation.no.sessions".localized)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            
            // Motivational message
            if viewModel.todayMeditationTime >= viewModel.dailyGoal {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                    
                    Text("meditation.goal.completed".localized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                    
                    Spacer()
                }
                .padding(.vertical, 4)
            } else {
                let remaining = viewModel.dailyGoal - viewModel.todayMeditationTime
                HStack {
                    Image(systemName: "target")
                        .font(.title3)
                        .foregroundColor(.orange)
                    
                    Text("\(remaining) \("meditation.minutes.remaining".localized)")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                    
                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    @ViewBuilder
    private func sessionBubble(session: MeditationSession) -> some View {
        VStack(spacing: 4) {
            Text(session.timeString)
                .font(.caption2)
                .foregroundColor(.white)
            
            Text("\(session.duration)m")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .shadow(color: .purple.opacity(0.3), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Timer Card
    @ViewBuilder
    private var timerCard: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "timer")
                    .font(.title2)
                    .foregroundColor(.purple)
                
                Text("meditation.timer".localized)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            // Timer Display
            ZStack {
                Circle()
                    .stroke(Color.purple.opacity(0.2), lineWidth: 8)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(1.0 - Double(viewModel.timeRemaining) / Double(viewModel.selectedTimer * 60)))
                    .stroke(
                        LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1), value: viewModel.timeRemaining)
                
                VStack(spacing: 8) {
                    Text(viewModel.formatTime(viewModel.timeRemaining))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(viewModel.isTimerRunning ? "meditation.meditating".localized : "meditation.ready".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Timer Options
            if !viewModel.isTimerRunning {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.timerOptions, id: \.self) { duration in
                            Button(action: {
                                viewModel.selectTimer(duration)
                            }) {
                                Text("\(duration)m")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(viewModel.selectedTimer == duration ? .white : .purple)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(viewModel.selectedTimer == duration ? .purple : .purple.opacity(0.1))
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Control Buttons
            HStack(spacing: 16) {
                if !viewModel.isTimerRunning {
                    Button(action: viewModel.startTimer) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                            Text("meditation.start".localized)
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing))
                        )
                    }
                } else {
                    Button(action: viewModel.pauseTimer) {
                        HStack(spacing: 8) {
                            Image(systemName: "pause.fill")
                            Text("meditation.pause".localized)
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.orange)
                        )
                    }
                    
                    Button(action: viewModel.stopTimer) {
                        HStack(spacing: 8) {
                            Image(systemName: "stop.fill")
                            Text("meditation.stop".localized)
                        }
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.red, lineWidth: 2)
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Breathing Exercises Card
    @ViewBuilder
    private var breathingExercisesCard: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "lungs.fill")
                    .font(.title2)
                    .foregroundColor(.cyan)
                
                Text("meditation.breathing".localized)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            // Breathing Technique Selector
            if !viewModel.isBreathingExerciseActive {
                VStack(spacing: 12) {
                    ForEach(BreathingTechnique.allCases, id: \.self) { technique in
                        breathingTechniqueRow(technique: technique)
                    }
                }
            } else {
                // Active Breathing Exercise
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.cyan.opacity(0.3), .blue.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: viewModel.breathingPhase == .inhale ? 150 : 100, height: viewModel.breathingPhase == .inhale ? 150 : 100)
                            .animation(.easeInOut(duration: Double(viewModel.selectedBreathingTechnique.duration)), value: viewModel.breathingPhase)
                        
                        Text(viewModel.breathingPhase.instruction.localized)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    
                    Text("meditation.cycle".localized + " \(viewModel.breathingCount)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Button(action: viewModel.stopBreathingExercise) {
                        Text("meditation.stop".localized)
                            .font(.headline)
                            .foregroundColor(.red)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.red, lineWidth: 2)
                            )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Helper Views
    @ViewBuilder
    private func statItem(title: String, value: String, unit: String, color: Color, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private func breathingTechniqueRow(technique: BreathingTechnique) -> some View {
        Button(action: {
            viewModel.selectBreathingTechnique(technique)
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(technique.name.localized)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(technique.description.localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.cyan)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cyan.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Ambient Sounds
    @ViewBuilder
    private var ambientSoundsCard: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: viewModel.isAmbientSoundPlaying ? "speaker.wave.3.fill" : "speaker.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text("meditation.ambient.sounds".localized)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if viewModel.isAmbientSoundPlaying {
                    Button(action: viewModel.stopAmbientSound) {
                        Image(systemName: "stop.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                }
            }
            
            // Volume Control (when playing)
            if viewModel.isAmbientSoundPlaying {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "speaker.fill")
                            .foregroundColor(.green)
                        
                        Slider(value: $viewModel.ambientVolume, in: 0...1) { _ in
                            viewModel.updateVolume()
                        }
                        
                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundColor(.green)
                    }
                    
                    Text("meditation.volume".localized + ": \(Int(viewModel.ambientVolume * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Sound Options Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(AmbientSound.allCases, id: \.self) { sound in
                    ambientSoundButton(sound: sound)
                }
            }
            
            // Currently Playing Info
            if viewModel.isAmbientSoundPlaying && viewModel.selectedAmbientSound != .none {
                HStack {
                    Image(systemName: "music.note")
                        .foregroundColor(.green)
                    
                    Text("meditation.now.playing".localized + ": " + viewModel.selectedAmbientSound.name.localized)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Animated sound waves
                    HStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.green)
                                .frame(width: 3, height: CGFloat.random(in: 8...20))
                                .animation(
                                    .easeInOut(duration: 0.5)
                                    .repeatForever()
                                    .delay(Double(index) * 0.1),
                                    value: viewModel.isAmbientSoundPlaying
                                )
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    @ViewBuilder
    private func ambientSoundButton(sound: AmbientSound) -> some View {
        Button(action: {
            if viewModel.selectedAmbientSound == sound && viewModel.isAmbientSoundPlaying {
                viewModel.stopAmbientSound()
            } else {
                viewModel.playAmbientSound(sound)
            }
        }) {
            VStack(spacing: 8) {
                Image(systemName: sound.icon)
                    .font(.title2)
                    .foregroundColor(
                        viewModel.selectedAmbientSound == sound && viewModel.isAmbientSoundPlaying 
                            ? .white 
                            : sound.color
                    )
                
                Text(sound.name.localized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(
                        viewModel.selectedAmbientSound == sound && viewModel.isAmbientSoundPlaying 
                            ? .white 
                            : .primary
                    )
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        viewModel.selectedAmbientSound == sound && viewModel.isAmbientSoundPlaying
                            ? LinearGradient(colors: [sound.color, sound.color.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [sound.color.opacity(0.1), sound.color.opacity(0.05)], startPoint: .top, endPoint: .bottom)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                sound.color.opacity(viewModel.selectedAmbientSound == sound && viewModel.isAmbientSoundPlaying ? 0.8 : 0.3), 
                                lineWidth: viewModel.selectedAmbientSound == sound && viewModel.isAmbientSoundPlaying ? 2 : 1
                            )
                    )
            )
            .scaleEffect(viewModel.selectedAmbientSound == sound && viewModel.isAmbientSoundPlaying ? 1.05 : 1.0)
            .shadow(
                color: viewModel.selectedAmbientSound == sound && viewModel.isAmbientSoundPlaying ? sound.color.opacity(0.3) : .clear,
                radius: 8, x: 0, y: 4
            )
        }
    }
    
    // MARK: - Progress Card (Placeholder)
    @ViewBuilder
    private var progressCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(.indigo)
                
                Text("meditation.progress".localized)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            // Weekly progress placeholder
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7) { index in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(width: 24, height: CGFloat.random(in: 10...60))
                        
                        Text(viewModel.dayOfWeek(index))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Manual Session Entry
    private func showManualSessionEntry() {
        manualSessionDuration = ""
        showingManualSessionAlert = true
    }
}

// MARK: - Timer Functions - Now handled by ViewModel

// MARK: - Ambient Sound Functions


// MARK: - Breathing Exercise Functions - Now handled by ViewModel

// MARK: - Data Management - Now handled by ViewModel

// MARK: - Custom Button Style
struct FloatingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
