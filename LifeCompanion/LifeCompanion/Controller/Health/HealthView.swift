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
                    
                    // Debug current water goal
                    print("🏥 HealthView onAppear - Current water goal: \(settingsManager.dailyWaterGoal)ml")
                    if let todayIntake = viewModel.todayWaterIntake {
                        print("🏥 Today's water intake goal: \(todayIntake.dailyGoal)ml")
                    }
                } catch {
                }
            }
        }
        .onReceive(settingsManager.objectWillChange) { _ in
            // Settings değiştiğinde health view'ı güncelle
            print("🔄 SettingsManager objectWillChange received")
            updateWaterGoal()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("WaterGoalUpdated"))) { notification in
            // Su hedefi değiştiğinde özel olarak güncelle
            print("🌊 HealthView received WaterGoalUpdated notification")
            updateWaterGoal()
        }
        .onChange(of: settingsManager.dailyWaterGoal) { oldValue, newValue in
            // Su hedefi değiştiğinde direkt güncelle
            print("🎯 Water goal changed from \(oldValue)ml to \(newValue)ml")
            updateWaterGoal()
        }
        .sheet(isPresented: $showingBodyMetricsEdit) {
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
        print("🔄 updateWaterGoal called - New goal: \(settingsManager.dailyWaterGoal)ml")
        
        // Bugünkü intake'i güncelle
        if let todayIntake = viewModel.todayWaterIntake {
            print("🌊 Old goal: \(todayIntake.dailyGoal)ml -> New goal: \(settingsManager.dailyWaterGoal)ml")
            todayIntake.dailyGoal = settingsManager.dailyWaterGoal
            
            do {
                try modelContext.save()
                print("✅ Water goal updated successfully to \(todayIntake.dailyGoal)ml")
            } catch {
                print("❌ Water goal update failed: \(error)")
            }
        } else {
            print("⚠️ No todayWaterIntake found, fetching...")
            viewModel.fetchTodayWaterIntake(from: modelContext)
            
            // Tekrar dene
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let todayIntake = viewModel.todayWaterIntake {
                    todayIntake.dailyGoal = settingsManager.dailyWaterGoal
                    try? modelContext.save()
                    print("✅ Water goal updated after fetch: \(todayIntake.dailyGoal)ml")
                }
            }
        }
        
        // ViewModel'i güncelle ve UI'ı refresh et
        viewModel.updateFromSettings(settingsManager)
        viewModel.objectWillChange.send()
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
                
                if let intake = viewModel.todayWaterIntake {
                    Text("\(intake.totalAmountInMl)ml/\(settingsManager.dailyWaterGoal)ml")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
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
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "figure.arms.open")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text("health.body.metrics".localized)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("health.edit".localized) {
                    editHeight = String(Int(viewModel.height))
                    editWeight = String(Int(viewModel.weight))
                    showingBodyMetricsEdit = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("health.height".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(viewModel.height)) cm")
                        .font(.title3)
                        .fontWeight(.medium)
                }
                
                VStack(alignment: .leading) {
                    Text("health.weight".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(viewModel.weight)) kg")
                        .font(.title3)
                        .fontWeight(.medium)
                }
                
                VStack(alignment: .leading) {
                    Text("health.bmi".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f", viewModel.bmi))
                        .font(.title3)
                        .fontWeight(.medium)
                }
            }
            
            Text(viewModel.bmiCategory)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.orange.opacity(0.1))
                        .overlay(
                            Capsule().stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                )
                .foregroundColor(.orange)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("health.water.goal".localized)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Toggle("health.use.calculated".localized, isOn: Binding(
                        get: { viewModel.useCalculatedGoal },
                        set: { _ in viewModel.toggleGoalType(in: modelContext) }
                    ))
                        .toggleStyle(SwitchToggleStyle())
                    
                    Spacer()
                }
                
                HStack {
                    Text("\("health.daily.goal".localized): \(viewModel.dailyWaterGoal)ml")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if !viewModel.useCalculatedGoal {
                        Button("health.change".localized) {
                            manualGoalInput = String(viewModel.manualWaterGoal)
                            showingManualGoalInput = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
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
                // Immediate haptic feedback
                if medication.completionPercentage >= 1.0 {
                    feedbackManager.warningHaptic()
                    selectedMedication = medication
                    showingOverdoseAlert = true
                } else {
                    feedbackManager.buttonTap()
                    takeMedication(medication)
                }
            }) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
            }
            .buttonStyle(.borderless) // Use borderless style for better tap handling
        }
        .padding(12)
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
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("health.edit.body.metrics".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    Text("health.edit.body.description".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("health.height".localized)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack {
                            TextField("170", text: $editHeight)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Text("cm")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("health.weight".localized)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack {
                            TextField("70", text: $editWeight)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Text("kg")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if let height = Double(editHeight), let weight = Double(editWeight), height > 0, weight > 0 {
                    let newBMI = weight / ((height / 100) * (height / 100))
                    let waterGoal = Int(weight * 35)
                    
                    VStack(spacing: 12) {
                        Text("health.preview".localized)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 20) {
                            VStack {
                                Text("health.bmi".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.1f", newBMI))
                                    .font(.title3)
                                    .fontWeight(.medium)
                            }
                            
                            VStack {
                                Text("health.water.goal".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(waterGoal)ml")
                                    .font(.title3)
                                    .fontWeight(.medium)
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("health.edit.body.metrics".localized)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.cancel".localized) {
                        showingBodyMetricsEdit = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.save".localized) {
                        if let height = Double(editHeight), let weight = Double(editWeight),
                           height > 0, weight > 0 {
                            viewModel.updateBodyMetrics(height: height, weight: weight, in: modelContext)
                            showingBodyMetricsEdit = false
                        }
                    }
                    .disabled(editHeight.isEmpty || editWeight.isEmpty || 
                             Double(editHeight) == nil || Double(editWeight) == nil ||
                             Double(editHeight)! <= 0 || Double(editWeight)! <= 0)
                }
            }
        }
    }
    
    private func dayOfWeek(_ index: Int) -> String {
        let days = ["health.day.mon", "health.day.tue", "health.day.wed", "health.day.thu", "health.day.fri", "health.day.sat", "health.day.sun"]
        return days[index].localized
    }
    
    // MARK: - Medication Actions
    private func takeMedication(_ medication: MedicationEntry) {
        print("\n💊 TAKING MEDICATION: \(medication.medicationName)")
        print("📋 Frequency: \(medication.frequency)")
        
        // Debug scheduled times
        let todayScheduled = medication.scheduledTimes.filter { Calendar.current.isDateInToday($0) }
        print("📅 Total scheduled times: \(medication.scheduledTimes.count)")
        print("📅 Today scheduled times: \(todayScheduled.count)")
        
        if todayScheduled.isEmpty {
            print("⚠️ ERROR: No scheduled times for today!")
            print("� All scheduled times:")
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            for time in medication.scheduledTimes {
                print("   - \(formatter.string(from: time))")
            }
        }
        
        let todayTaken = medication.takenTimes.filter { Calendar.current.isDateInToday($0) }
        print("✅ Before: \(todayTaken.count)/\(todayScheduled.count)")
        print("✅ Current completion: \(Int(medication.completionPercentage * 100))%")
        
        // Mark medication as taken
        let currentTime = Date()
        medication.takenTimes.append(currentTime)
        print("✅ Added taken time: \(currentTime)")
        
        let newTodayTaken = medication.takenTimes.filter { Calendar.current.isDateInToday($0) }
        let newPercentage = todayScheduled.count > 0 ? Double(newTodayTaken.count) / Double(todayScheduled.count) : 0
        print("✅ After: \(newTodayTaken.count)/\(todayScheduled.count) = \(Int(newPercentage * 100))%")
        print("✅ New completion should be: \(Int(medication.completionPercentage * 100))%")
        
        // Save to context with error handling
        do {
            try modelContext.save()
            print("✅ Context saved successfully")
            
            // Additional debugging - check if data persisted
            let allMeds = try modelContext.fetch(FetchDescriptor<MedicationEntry>())
            if let savedMed = allMeds.first(where: { $0.id == medication.id }) {
                let savedTodayTaken = savedMed.takenTimes.filter { Calendar.current.isDateInToday($0) }
                print("✅ Verified - saved medication has \(savedTodayTaken.count) taken times today")
                print("✅ Verified - completion percentage: \(Int(savedMed.completionPercentage * 100))%")
            }
            
            // SwiftData @Query will automatically refresh the UI
        } catch {
            print("❌ Error saving medication: \(error)")
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
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
    
    // MARK: - Notification Permission
    private func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false)
                } else {
                    print(granted ? "✅ Notification permission granted" : "❌ Notification permission denied")
                    completion(granted)
                }
            }
        }
    }
}
