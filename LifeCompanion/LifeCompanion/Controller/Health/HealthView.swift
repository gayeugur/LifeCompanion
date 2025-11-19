//
//  HealthView.swift
//  LifeCompanion
//
//  Created by gayeugur on 3.11.2025.
//

import SwiftUI
import SwiftData
import UserNotifications

struct HealthView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = HealthViewModel()
    @EnvironmentObject private var settingsManager: SettingsManager
    @EnvironmentObject private var feedbackManager: FeedbackManager
    
    // SwiftData Query for medications - simplified
    @Query(sort: \MedicationEntry.createdAt, order: .reverse) 
    private var allMedications: [MedicationEntry]
    
    // Computed property for active medications
    private var medications: [MedicationEntry] {
        allMedications.filter { $0.isActive }
    }
    
    // Edit Body Metrics Sheet
    @State private var showingBodyMetricsEdit = false
    @State private var editHeight: String = ""
    @State private var editWeight: String = ""
    
    // Manual Goal Input
    @State private var showingManualGoalInput = false
    @State private var manualGoalInput: String = ""
    
    // Add Medication
    @State private var showingAddMedication = false
    
    // Overdose Alert
    @State private var showingOverdoseAlert = false
    @State private var selectedMedication: MedicationEntry?
    
    // Delete Confirmation
    @State private var showingDeleteAlert = false
    @State private var medicationToDelete: MedicationEntry?
    
    // Water Goal Settings
    @State private var showingWaterGoalSettings = false
    
    // Water goal options (in ml)
    private let waterGoalOptions = [1500, 2000, 2500, 3000, 3500, 4000]
    
    // Medication refresh trigger
    @State private var medicationRefreshTrigger = UUID()
    
    var body: some View {
        Group {
            if viewModel.todayWaterIntake != nil {
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Water Intake Card
                        waterIntakeCard
                        
                        // Quick Actions
                        quickActionsCard
                        
                        // Body Metrics & Goal Settings
                        bodyMetricsCard
                        
                        // Medication Tracking
                        medicationCard
                        
                        // Weekly Progress
                        weeklyProgressCard
                        
                        // Health Tips
                        healthTipsCard
                    }
                    .padding(20)
                }
            } else {
                // Loading state
                VStack {
                    ProgressView("Loading health data...")
                        .foregroundColor(Color.primaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.primaryBackground)
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color.red.opacity(0.12),
                    Color.pink.opacity(0.08), 
                    Color.red.opacity(0.04),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle("menu.health".localized)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            Task { @MainActor in
                do {
                    // Settings manager integration first
                    viewModel.updateFromSettings(settingsManager)
                    
                    // Load saved data
                    viewModel.loadBodyMetrics()
                    viewModel.loadDailyQuickActions()
                    
                    // Fetch data from context
                    viewModel.fetchTodayWaterIntake(from: modelContext)
                    viewModel.fetchWeeklyData(from: modelContext)
                    viewModel.fetchTodayMedications(from: modelContext)
                    
                    // Check for auto reset
                    viewModel.checkAutoReset(context: modelContext)
                    
                } catch {
                }
            }
        }
        .onReceive(settingsManager.objectWillChange) { _ in
            // Settings değiştiğinde health view'ı güncelle
            updateWaterGoal()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("WaterGoalUpdated"))) { notification in
            // Su hedefi değiştiğinde özel olarak güncelle
            // Debug: Water goal notification received
            updateWaterGoal()
        }
        .onChange(of: settingsManager.dailyWaterGoal) { oldValue, newValue in
            // Su hedefi değiştiğinde direkt güncelle
            // Debug: onChange detected
            updateWaterGoal()
        }
        .fullScreenCover(isPresented: $showingBodyMetricsEdit) {
            bodyMetricsEditSheet
        }
        .alert("health.set.manual.goal".localized, isPresented: $showingManualGoalInput) {
            TextField("health.goal.placeholder".localized, text: $manualGoalInput)
                .keyboardType(.numberPad)
            
            Button("common.cancel".localized, role: .cancel) { }
            
            Button("common.save".localized) {
                if let goal = Int(manualGoalInput), goal > 0 {
                    viewModel.updateManualGoal(goal)
                    if let todayIntake = viewModel.todayWaterIntake {
                        todayIntake.dailyGoal = goal
                        viewModel.save(modelContext)
                    }
                }
            }
        } message: {
            Text("health.manual.goal.description".localized)
        }
        .alert("health.overdose.warning.title".localized, isPresented: $showingOverdoseAlert) {
            Button("common.cancel".localized, role: .cancel) { }
            
            Button("health.take.anyway".localized, role: .destructive) {
                if let medication = selectedMedication {
                    takeMedication(medication)
                }
            }
        } message: {
            if let medication = selectedMedication {
                Text(String(format: "health.overdose.warning.message".localized, medication.medicationName))
            }
        }
        .alert("health.delete.confirmation.title".localized, isPresented: $showingDeleteAlert) {
            Button("common.cancel".localized, role: .cancel) { }
            
            Button("common.delete".localized, role: .destructive) {
                if let medication = medicationToDelete {
                    deleteMedication(medication)
                    medicationToDelete = nil
                }
            }
        } message: {
            if let medication = medicationToDelete {
                Text(String(format: "health.delete.confirmation.message".localized, medication.medicationName))
            }
        }
        .confirmationDialog(
            "Water Goal Settings",
            isPresented: $showingWaterGoalSettings,
            presenting: waterGoalOptions
        ) { options in
            ForEach(options, id: \.self) { goal in
                Button("\(goal)ml") {
                    // Update settings manager first
                    settingsManager.dailyWaterGoal = goal
                    
                    // Force immediate update of today's water intake
                    if let todayIntake = viewModel.todayWaterIntake {
                        todayIntake.dailyGoal = goal
                        
                        // Save changes to SwiftData
                        do {
                            try modelContext.save()
                        } catch {
                            print("Failed to save water goal: \(error)")
                        }
                    }
                    
                    // Update view model
                    viewModel.updateFromSettings(settingsManager)
                    
                    // Trigger UI refresh
                    DispatchQueue.main.async {
                        viewModel.objectWillChange.send()
                    }
                    
                    feedbackManager.lightHaptic()
                }
            }
            
            Button("Cancel", role: .cancel) { }
        } message: { _ in
            Text("Select your daily water goal")
        }
        .sheet(isPresented: $showingAddMedication) {
            AddMedicationView { medication in
                // Add medication to context
                modelContext.insert(medication)
                
                // Save - @Query will automatically update
                do {
                    try modelContext.save()
                    
                    // Request notification permission and schedule
                    requestNotificationPermission { granted in
                        if granted && settingsManager.notificationsEnabled {
                            medication.scheduleNotifications(notificationsEnabled: true)
                        } else {
                            // Don't schedule if notifications are disabled or permission denied
                        }
                    }
                } catch {
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func updateWaterGoal() {
        // Bugünkü intake'i güncelle
        if let todayIntake = viewModel.todayWaterIntake {
            todayIntake.dailyGoal = settingsManager.dailyWaterGoal
            
            do {
                try modelContext.save()
            } catch { 
                print("Failed to save water goal: \(error)")
            }
        } else {
            viewModel.fetchTodayWaterIntake(from: modelContext)
            
            // Tekrar dene
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let todayIntake = viewModel.todayWaterIntake {
                    todayIntake.dailyGoal = settingsManager.dailyWaterGoal
                    try? modelContext.save()
                }
            }
        }
        
        // ViewModel'i güncelle ve UI'ı refresh et
        viewModel.updateFromSettings(settingsManager)
        viewModel.objectWillChange.send()
        
        // Force UI refresh after a small delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            viewModel.objectWillChange.send()
        }
    }
    
    // MARK: - Quick Water Button Helper
    @ViewBuilder
    private func quickWaterButton(amount: Int, in context: ModelContext) -> some View {
        Button(action: {
            viewModel.addWaterAmount(amount, in: context)
        }) {
            Text("\(amount)ml")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .scaleEffect(0.9)
        .animation(.easeInOut(duration: 0.1), value: viewModel.todayWaterIntake?.amount)
    }
    
    // MARK: - Header Section
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 12) {
            let motivation = viewModel.getMotivationalMessage()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(motivation.title.localized)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(motivation.message.localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(motivation.emoji)
                    .font(.system(size: 40))
                    .scaleEffect(1.0)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: viewModel.todayWaterIntake?.progressPercentage ?? 0)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .blue.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Water Intake Card
    @ViewBuilder
    private var waterIntakeCard: some View {
        VStack(spacing: 20) {
            // Title
            HStack {
                Image(systemName: "drop.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("health.water.title".localized)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Water Goal Settings Button
                Button(action: {
                    showingWaterGoalSettings = true
                    feedbackManager.lightHaptic()
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundColor(.blue.opacity(0.7))
                }
                
                if let intake = viewModel.todayWaterIntake {
                    Text("\(intake.totalAmountInMl)ml/\(settingsManager.dailyWaterGoal)ml")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .onAppear {
                            // Auto-refresh when view appears
                        }
                        .onLongPressGesture {
                            if intake.amount > 0 {
                                withAnimation(.spring()) {
                                    viewModel.resetWaterIntake(context: modelContext)
                                }
                            }
                        }
                }
                
                // Reset Button
                if let intake = viewModel.todayWaterIntake, intake.amount > 0 {
                    Button(action: {
                        withAnimation(.spring()) {
                            viewModel.resetWaterIntake(context: modelContext)
                        }
                    }) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.title3)
                            .foregroundColor(.red.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Progress Ring
            if let intake = viewModel.todayWaterIntake {
                ZStack {
                    // Background Circle
                    Circle()
                        .stroke(Color.blue.opacity(0.2), lineWidth: 12)
                        .frame(width: 120, height: 120)
                    
                    // Progress Circle
                    Circle()
                        .trim(from: 0.0, to: intake.amountProgressPercentage)
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.8), value: intake.amountProgressPercentage)
                    
                    // Center Content
                    VStack(spacing: 4) {
                        Text("\(Int(intake.amountProgressPercentage * 100))%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        if intake.totalAmountInMl < settingsManager.dailyWaterGoal {
                            let remainingML = max(0, settingsManager.dailyWaterGoal - intake.totalAmountInMl)
                            Text("\(remainingML)ml \("health.water.remaining".localized)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("health.water.goal.reached".localized)
                                .font(.caption)
                                .foregroundColor(.green)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            
            // Quick Add Buttons (ml-based)
            VStack(spacing: 12) {
                // Main add/remove buttons
                HStack(spacing: 20) {
                    Button(action: {
                        viewModel.removeWaterAmount(250, in: modelContext)
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title)
                            .foregroundColor(.red)
                    }
                    .disabled(viewModel.todayWaterIntake?.amount == 0)
                    
                    Spacer()
                    
                    Button(action: {
                        feedbackManager.buttonTap()
                        viewModel.addWaterAmount(250, in: modelContext)
                    }) {
                        VStack(spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                            }
                            .padding(.bottom, 2)
                            
                            VStack(spacing: 2) {
                                Text("health.water.add.glass".localized)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text("(250ml)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // Goal setting functionality can be added here
                    }) {
                        Image(systemName: "target")
                            .font(.title)
                            .foregroundColor(.orange)
                    }
                }
                
                // Quick ml amount buttons
                HStack(spacing: 12) {
                    quickWaterButton(amount: 100, in: modelContext)
                    quickWaterButton(amount: 200, in: modelContext)
                    quickWaterButton(amount: 500, in: modelContext)
                    quickWaterButton(amount: 750, in: modelContext)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.blue.opacity(0.15), lineWidth: 1)
                )
        )
        .shadow(color: .blue.opacity(0.1), radius: 12, x: 0, y: 6)
    }
    
    // MARK: - Quick Actions
    @ViewBuilder
    private var quickActionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text("health.quick.actions".localized)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                quickActionButton(
                    icon: viewModel.coffeeCount > 0 ? "cup.and.saucer.fill" : "cup.and.saucer",
                    title: "health.action.coffee",
                    subtitle: viewModel.coffeeCount > 0 ? "\(viewModel.coffeeCount)" : nil,
                    color: .brown,
                    isCompleted: viewModel.coffeeCount > 0,
                    onTap: {
                        withAnimation(.spring()) {
                            viewModel.incrementCoffee()
                        }
                    },
                    onLongPress: viewModel.coffeeCount > 0 ? {
                        withAnimation(.spring()) {
                            viewModel.resetCoffee()
                        }
                    } : nil
                )
                
                quickActionButton(
                    icon: viewModel.walkSteps > 0 ? "figure.walk.circle.fill" : "figure.walk",
                    title: "health.action.walk",
                    subtitle: viewModel.walkSteps > 0 ? "\(viewModel.walkSteps) \("health.steps".localized)" : nil,
                    color: .green,
                    isCompleted: viewModel.walkSteps > 0,
                    onTap: {
                        withAnimation(.spring()) {
                            viewModel.incrementSteps()
                        }
                    },
                    onLongPress: viewModel.walkSteps > 0 ? {
                        withAnimation(.spring()) {
                            viewModel.resetSteps()
                        }
                    } : nil
                )
                
                quickActionButton(
                    icon: viewModel.sleepLogged ? "bed.double.fill" : "bed.double",
                    title: "health.action.sleep",
                    subtitle: viewModel.sleepLogged ? "health.logged".localized : nil,
                    color: .indigo,
                    isCompleted: viewModel.sleepLogged,
                    onTap: {
                        withAnimation(.spring()) {
                            viewModel.toggleSleep()
                        }
                    }
                )
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
    private func quickActionButton(
        icon: String,
        title: String,
        subtitle: String? = nil,
        color: Color,
        isCompleted: Bool = false,
        onTap: @escaping () -> Void,
        onLongPress: (() -> Void)? = nil
    ) -> some View {
        VStack(spacing: 6) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isCompleted ? .white : color)
                
                Text(title.localized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isCompleted ? .white : .primary)
                    .multilineTextAlignment(.center)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(isCompleted ? .white.opacity(0.9) : color)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isCompleted 
                            ? LinearGradient(colors: [color, color.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [color.opacity(0.1), color.opacity(0.05)], startPoint: .top, endPoint: .bottom)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(isCompleted ? 0.6 : 0.2), lineWidth: isCompleted ? 2 : 1)
                    )
            )
            .scaleEffect(isCompleted ? 1.05 : 1.0)
            .shadow(color: isCompleted ? color.opacity(0.3) : .clear, radius: isCompleted ? 8 : 0, x: 0, y: 4)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
            .onLongPressGesture {
                onLongPress?()
            }
        }
    }
    
    // MARK: - Weekly Progress
    @ViewBuilder
    private var weeklyProgressCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
                
                Text("health.weekly.progress".localized)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            // Weekly chart placeholder
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7) { index in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(width: 24, height: CGFloat.random(in: 20...80))
                        
                        Text(dayOfWeek(index))
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
    
    // MARK: - Body Metrics Card
    @ViewBuilder
    private var bodyMetricsCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with gradient background
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.orange.opacity(0.2), .pink.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "figure.arms.open")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("health.body.metrics".localized)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Track your health metrics")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        editHeight = String(Int(viewModel.height))
                        editWeight = String(Int(viewModel.weight))
                        showingBodyMetricsEdit = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                                .font(.caption)
                            Text("health.edit".localized)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(.blue.opacity(0.1))
                        )
                        .foregroundColor(.blue)
                    }
                }
                
                // Metrics Cards
                HStack(spacing: 12) {
                    // Height Card
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.green.opacity(0.15), .mint.opacity(0.1)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "ruler")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.green)
                        }
                        
                        VStack(spacing: 2) {
                            Text("health.height".localized)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                                .fontWeight(.medium)
                            
                            Text("\(Int(viewModel.height))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("cm")
                                .font(.caption)
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.regularMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.green.opacity(0.2), lineWidth: 1)
                            )
                    )
                    
                    // Weight Card
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.blue.opacity(0.15), .cyan.opacity(0.1)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "scalemass")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.blue)
                        }
                        
                        VStack(spacing: 2) {
                            Text("health.weight".localized)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                                .fontWeight(.medium)
                            
                            Text("\(Int(viewModel.weight))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("kg")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.regularMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.blue.opacity(0.2), lineWidth: 1)
                            )
                    )
                    
                    // BMI Card
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.orange.opacity(0.15), .yellow.opacity(0.1)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "heart.text.square")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.orange)
                        }
                        
                        VStack(spacing: 2) {
                            Text("health.bmi".localized)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                                .fontWeight(.medium)
                            
                            Text(String(format: "%.1f", viewModel.bmi))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("BMI")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .fontWeight(.medium)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.regularMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.orange.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                
                // BMI Category Badge
                HStack {
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(getBMIColor(for: viewModel.bmiCategory))
                            .frame(width: 8, height: 8)
                        
                        Text(viewModel.bmiCategory)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(getBMIColor(for: viewModel.bmiCategory).opacity(0.1))
                            .overlay(
                                Capsule().stroke(getBMIColor(for: viewModel.bmiCategory).opacity(0.3), lineWidth: 1)
                            )
                    )
                    .foregroundColor(getBMIColor(for: viewModel.bmiCategory))
                    
                    Spacer()
                }
            }
            
            // Water Goal Section
            VStack(alignment: .leading, spacing: 16) {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [.blue.opacity(0.1), .cyan.opacity(0.05)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(height: 1)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.cyan.opacity(0.2), .blue.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 28, height: 28)
                            
                            Image(systemName: "drop.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.cyan)
                        }
                        
                        Text("health.water.goal".localized)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                    }
                    
                    VStack(spacing: 12) {
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: viewModel.useCalculatedGoal ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(viewModel.useCalculatedGoal ? .green : .secondary)
                                    .font(.system(size: 16))
                                
                                Text("health.use.calculated".localized)
                                    .font(.callout)
                                    .fontWeight(.medium)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: Binding(
                                get: { viewModel.useCalculatedGoal },
                                set: { _ in viewModel.toggleGoalType(in: modelContext) }
                            ))
                                .toggleStyle(SwitchToggleStyle(tint: .cyan))
                                .scaleEffect(0.8)
                        }
                        
                        // Goal Display Card
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("health.daily.goal".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                    .fontWeight(.medium)
                                
                                HStack(alignment: .bottom, spacing: 2) {
                                    Text("\(viewModel.dailyWaterGoal)")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    
                                    Text("ml")
                                        .font(.caption)
                                        .foregroundColor(.cyan)
                                        .fontWeight(.medium)
                                        .padding(.bottom, 2)
                                }
                            }
                            
                            Spacer()
                            
                            if !viewModel.useCalculatedGoal {
                                Button {
                                    manualGoalInput = String(settingsManager.dailyWaterGoal)
                                    showingManualGoalInput = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "slider.horizontal.3")
                                            .font(.caption)
                                        Text("health.change".localized)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(.cyan.opacity(0.1))
                                    )
                                    .foregroundColor(.cyan)
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.regularMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(.cyan.opacity(0.2), lineWidth: 1)
                                )
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
    
    // MARK: - Medication Card
    @ViewBuilder
    private var medicationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "pills.fill")
                    .font(.title2)
                    .foregroundColor(.red)
                
                Text("health.medications".localized)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    showingAddMedication = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.red)
                }
            }
            
            if medications.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "pills")
                        .font(.system(size: 32))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("health.no.medications".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // Use VStack with manual swipe gestures for better control
                VStack(spacing: 8) {
                    ForEach(medications) { medication in
                        medicationRowView(medication)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.tertiaryBackground)
                            )
                            .contextMenu {
                                Button("Delete", role: .destructive) {
                                    showDeleteAlert(for: medication)
                                }
                            }
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
    
    @ViewBuilder
    private func medicationRow(_ medication: MedicationEntry) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(medication.medicationName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(medication.dosage + " • " + medication.frequency.localizedName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let nextDose = medication.nextDoseTime {
                    Text("\("health.next.dose".localized): \(nextDose, style: .time)")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                let percentage = Int(medication.completionPercentage * 100)
                
                if medication.completionPercentage > 1.0 {
                    // Over 100% - show warning
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.title3)
                } else {
                    Circle()
                        .fill(medication.completionPercentage >= 1.0 ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 12, height: 12)
                }
                
                Text("\(percentage)%")
                    .font(.caption2)
                    .foregroundColor(medication.completionPercentage > 1.0 ? .orange : .secondary)
            }
            
            Button(action: {
                // Check for potential overdose
                if medication.completionPercentage >= 1.0 {
                    selectedMedication = medication
                    showingOverdoseAlert = true
                    return
                }
                
                // Mark medication as taken
                takeMedication(medication)
            }) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 8)
        .contextMenu {
            Button("Delete", role: .destructive) {
                showDeleteAlert(for: medication)
            }
        }
    }
    
    private func medicationRowView(_ medication: MedicationEntry) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(medication.medicationName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(medication.dosage + " • " + medication.frequency.localizedName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let nextDose = medication.nextDoseTime {
                    Text("\("health.next.dose".localized): \(nextDose, style: .time)")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                let percentage = Int(medication.completionPercentage * 100)
                
                if medication.completionPercentage > 1.0 {
                    // Over 100% - show warning
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.title3)
                } else {
                    Circle()
                        .fill(medication.completionPercentage >= 1.0 ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 12, height: 12)
                }
                
                Text("\(percentage)%")
                    .font(.caption2)
                    .foregroundColor(medication.completionPercentage > 1.0 ? .orange : .secondary)
            }
            
            Button(action: {
                // Check for overdose protection
                if medication.completionPercentage >= 1.0 {
                    feedbackManager.warningHaptic()
                    selectedMedication = medication
                    showingOverdoseAlert = true
                } else {
                    takeMedication(medication)
                }
            }) {
                ZStack {
                    Circle()
                        .fill(medication.completionPercentage >= 1.0 ? Color.green.opacity(0.3) : Color.green.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: medication.completionPercentage >= 1.0 ? "checkmark.circle.fill" : "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(medication.completionPercentage >= 1.0 ? .green : .green.opacity(0.7))
                }
            }
            .buttonStyle(.plain) // Use plain style for better interaction
            .contentShape(Circle()) // Make entire circular area tappable
        }
        .padding(12)
        .id("\(medication.id)_\(medicationRefreshTrigger)")
    }
    
    // MARK: - Health Tips Card
    @ViewBuilder
    private var healthTipsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                Text("health.tips.title".localized)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                healthTipRow(
                    icon: "drop.fill",
                    tip: "health.tip.water",
                    color: .blue
                )
                
                healthTipRow(
                    icon: "sun.max.fill",
                    tip: "health.tip.morning",
                    color: .orange
                )
                
                healthTipRow(
                    icon: "leaf.fill",
                    tip: "health.tip.breathing",
                    color: .green
                )
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
    private func healthTipRow(icon: String, tip: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(tip.localized)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
    
    // MARK: - Body Metrics Edit Sheet
    @ViewBuilder
    private var bodyMetricsEditSheet: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.1)
                .background(.ultraThinMaterial)
                .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header with close button
                HStack {
                    Button(action: {
                        showingBodyMetricsEdit = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.primary)
                            .frame(width: 32, height: 32)
                            .background(.regularMaterial)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("health.edit.body.metrics".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Invisible spacer for centering
                    Rectangle()
                        .fill(.clear)
                        .frame(width: 32, height: 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 30)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Description
                        Text("health.edit.body.description".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)

                
                // Input fields with modern design
                VStack(spacing: 16) {
                    // Height input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("health.height".localized)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 12) {
                            TextField("170", text: $editHeight)
                                .keyboardType(.numberPad)
                                .font(.title3)
                                .fontWeight(.medium)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            
                            Text("cm")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fontWeight(.medium)
                        }
                    }
                    
                    // Weight input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("health.weight".localized)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 12) {
                            TextField("70", text: $editWeight)
                                .keyboardType(.numberPad)
                                .font(.title3)
                                .fontWeight(.medium)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            
                            Text("kg")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Preview section with enhanced design
                if let height = Double(editHeight), let weight = Double(editWeight), height > 0, weight > 0 {
                    let newBMI = weight / ((height / 100) * (height / 100))
                    let (waterGoal, baseWaterPerKg) = calculateWaterGoal(bmi: newBMI, weight: weight)
                    
                    let bmiCategory: String = {
                        switch newBMI {
                        case ..<18.5:
                            return "health.bmi.underweight".localized
                        case 18.5..<25:
                            return "health.bmi.normal".localized
                        case 25..<30:
                            return "health.bmi.overweight".localized
                        default:
                            return "health.bmi.obese".localized
                        }
                    }()
                    let bmiColor = getBMIColor(for: bmiCategory)
                    
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "eye")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            Text("health.preview".localized)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                        
                        // BMI Category Badge
                        HStack(spacing: 8) {
                            Circle()
                                .fill(bmiColor)
                                .frame(width: 8, height: 8)
                            
                            Text(bmiCategory)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(bmiColor)
                            
                            Text("(BMI: \(String(format: "%.1f", newBMI)))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(bmiColor.opacity(0.1))
                                .overlay(
                                    Capsule().stroke(bmiColor.opacity(0.3), lineWidth: 1)
                                )
                        )
                        
                        HStack(spacing: 16) {
                            // BMI Preview Card
                            VStack(spacing: 8) {
                                Text("health.bmi".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fontWeight(.medium)
                                
                                Text(String(format: "%.1f", newBMI))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(bmiColor)
                                
                                Text(bmiCategory)
                                    .font(.caption2)
                                    .foregroundColor(bmiColor)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [bmiColor.opacity(0.1), bmiColor.opacity(0.05)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(bmiColor.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            
                            // Water Goal Preview Card
                            VStack(spacing: 8) {
                                Text("health.water.goal".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fontWeight(.medium)
                                
                                Text("\(waterGoal)ml")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                
                                Text("\(Int(baseWaterPerKg))ml/kg")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue.opacity(0.1), Color.cyan.opacity(0.05)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }
                        
                        // Water intake explanation
                        if viewModel.useCalculatedGoal {
                            VStack(spacing: 4) {
                                HStack(spacing: 6) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    
                                    Text("BMI tabanlı su hedefi hesaplama aktif")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text("Your water goal is automatically calculated based on your BMI category for optimal hydration.")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.blue.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(.blue.opacity(0.1), lineWidth: 1)
                                    )
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                        }
                    }
                    .padding(.bottom, 100) // Space for floating save button
                }
                
                Spacer()
                
                // Save button at bottom
                Button(action: {
                    if let height = Double(editHeight), let weight = Double(editWeight),
                       height > 0, weight > 0 {
                        viewModel.updateBodyMetrics(height: height, weight: weight, in: modelContext)
                        showingBodyMetricsEdit = false
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                        Text("common.save".localized)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(editHeight.isEmpty || editWeight.isEmpty || 
                         Double(editHeight) == nil || Double(editWeight) == nil ||
                         Double(editHeight)! <= 0 || Double(editWeight)! <= 0)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .onTapGesture {
            // Dismiss keyboard when tapping on empty space
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    private func dayOfWeek(_ index: Int) -> String {
        let days = ["health.day.mon", "health.day.tue", "health.day.wed", "health.day.thu", "health.day.fri", "health.day.sat", "health.day.sun"]
        return days[index].localized
    }
    
    // MARK: - Medication Actions
    private func takeMedication(_ medication: MedicationEntry) {
        // Mark medication as taken
        let currentTime = Date()
        medication.takenTimes.append(currentTime)
        
        // Save to context with error handling
        do {
            try modelContext.save()
            
            // Force comprehensive UI refresh
            DispatchQueue.main.async {
                // Trigger multiple refresh mechanisms
                self.viewModel.objectWillChange.send()
                self.medicationRefreshTrigger = UUID()
                
                // Force SwiftData to refresh
                try? self.modelContext.save()
            }
        } catch {
            print("Failed to save medication data: \(error)")
        }
        
        // Haptic feedback
        feedbackManager.successHaptic()
    }
    
    private func showDeleteAlert(for medication: MedicationEntry) {
        medicationToDelete = medication
        showingDeleteAlert = true
    }
    
    private func deleteMedication(_ medication: MedicationEntry) {
        // Cancel all pending notifications for this medication
        let identifiers = medication.getNotificationIdentifiers()
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        
        // Delete from SwiftData context
        modelContext.delete(medication)
        
        // Save context
        do {
            try modelContext.save()
        } catch {
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    // MARK: - BMI Color Helper
    private func getBMIColor(for category: String) -> Color {
        switch category.lowercased() {
        case let cat where cat.contains("underweight") || cat.contains("düşük"):
            return .blue
        case let cat where cat.contains("normal") || cat.contains("ideal"):
            return .green
        case let cat where cat.contains("overweight") || cat.contains("fazla"):
            return .orange
        case let cat where cat.contains("obese") || cat.contains("obez"):
            return .red
        default:
            return .orange
        }
    }
    
    // MARK: - Notification Permission
    private func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false)
                } else {
                    completion(granted)
                }
            }
        }
    }
    
    // MARK: - Water Goal Calculation Helper
    private func calculateWaterGoal(bmi: Double, weight: Double) -> (waterGoal: Int, baseWaterPerKg: Double) {
        let baseWaterPerKg: Double
        
        switch bmi {
        case ..<18.5:
            baseWaterPerKg = 40.0 // Underweight: Higher water intake
        case 18.5..<25:
            baseWaterPerKg = 35.0 // Normal: Standard water intake
        case 25..<30:
            baseWaterPerKg = 37.0 // Overweight: Slightly higher
        default:
            baseWaterPerKg = 40.0 // Obese: Higher for weight management
        }
        
        let waterGoal = max(min(Int(weight * baseWaterPerKg), 4000), 1500)
        return (waterGoal, baseWaterPerKg)
    }
}
