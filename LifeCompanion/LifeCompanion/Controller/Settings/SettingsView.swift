//
//  SettingsView.swift
//  LifeCompanion
//
//  Created on 7.11.2025.
//

import SwiftUI
import SwiftData
import UserNotifications
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var feedbackManager: FeedbackManager
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var dataManager: DataManager
    @ObservedObject var languageManager = LanguageManager.shared
    
    @State private var autoResetTime = Date()
    @State private var autoResetTimeData = Data()
    @State private var showingLanguageSheet = false
    @State private var showingAbout = false
    @State private var showingNotificationPermissionAlert = false
    @State private var showingDeleteConfirmation = false
    @State private var showingEmailAlert = false
    @State private var showingExportFormatAlert = false
    @State private var showingExportError = false
    @State private var isExporting = false
    
    private let languages = [
        ("system", "🌐 System Default", "Sistem Varsayılanı"),
        ("en", "🇺🇸 English", "English"),
        ("tr", "🇹🇷 Türkçe", "Türkçe")
    ]
    
    private let waterGoalOptions = [1500, 2000, 2500, 3000, 3500, 4000]
    private let gridSizeOptions = [3, 4, 5, 6]
    
    var body: some View {
        NavigationStack {
            settingsContent
                .navigationTitle("menu.settings".localized)
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("common.done".localized) {
                            dismiss()
                        }
                    }
                }
        }
        .onAppear { }
        .alert(LanguageManager.shared.getLocalizedString(for: "settings.export.format.title"), isPresented: $showingExportFormatAlert) {
            exportFormatAlert
        } message: {
            Text("settings.export.format.message".localized)
        }
        .alert("Export Error", isPresented: $showingExportError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Unable to export your data. Please try again.")
        }
        .alert("settings.support.email.failed.title".localized, isPresented: $showingEmailAlert) {
            Button("common.copy".localized) {
                UIPasteboard.general.string = "gayeugur00@gmail.com"
                feedbackManager.successHaptic()
            }
            Button("common.ok".localized, role: .cancel) { }
        } message: {
            #if targetEnvironment(simulator)
            Text("In simulator: Contact gayeugur00@gmail.com for support")
            #else
            Text("settings.support.email.failed.message".localized)
            #endif
        }
    }
    
    @ViewBuilder
    private var settingsContent: some View {
        ZStack {
            // Settings gradient background
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.08),
                    Color.purple.opacity(0.04),
                    Color.indigo.opacity(0.02),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(.container, edges: .bottom)
            
            ScrollView {
                LazyVStack(spacing: 20) {
                    // General Settings
                    generalSection
                    
                    // Habits Settings
                    habitsSection
                    
                    // Health Settings  
                    healthSection
                        
                    // Memory Game Settings
                    memoryGameSection
                    
                    // Privacy & Data
                    privacySection
                    
                    // About & Support
                    aboutSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 30)
            }
            .scrollContentBackground(.hidden)
            .clipped()
        }
        .onAppear {
            loadTimeDefaults()
        }
        .onChange(of: autoResetTime) { _, newValue in
            saveTime(newValue, isReminderTime: false)
        }
        .sheet(isPresented: $showingLanguageSheet) {
            languageSelectionSheet
        }
        .sheet(isPresented: $showingAbout) {
            aboutSheet
        }
        .alert("settings.notification.permission.title".localized, isPresented: $showingNotificationPermissionAlert) {
            Button("settings.notification.permission.settings".localized) {
                openAppSettings()
            }
            Button("common.cancel".localized, role: .cancel) { }
        } message: {
            Text("settings.notification.permission.message".localized)
        }
        .alert("settings.privacy.delete.title".localized, isPresented: $showingDeleteConfirmation) {
            Button("settings.privacy.delete.confirm".localized, role: .destructive) {
                deleteAllData()
            }
            Button("common.cancel".localized, role: .cancel) { }
        } message: {
            Text("settings.privacy.delete.message".localized)
        }
    }
    
    @ViewBuilder 
    private var exportFormatAlert: some View {
        Button(LanguageManager.shared.getLocalizedString(for: "settings.export.format.pdf")) {
            showingExportFormatAlert = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                exportUserData(format: .pdf)
            }
        }
        Button(LanguageManager.shared.getLocalizedString(for: "settings.export.format.json")) {
            showingExportFormatAlert = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                exportUserData(format: .json)
            }
        }
        Button("common.cancel".localized, role: .cancel) { }
    }
    

    // MARK: - General Section
    @ViewBuilder
    private var generalSection: some View {
        SettingsCard(title: "settings.general.title".localized, icon: "gear") {
            VStack(spacing: 16) {
                // Dark Mode Toggle
                HStack {
                    Label("settings.general.darkmode".localized, systemImage: "moon.fill")
                    Spacer()
                    Toggle("", isOn: $themeManager.isDarkMode)
                        .tint(.purple)
                        .onChange(of: themeManager.isDarkMode) { _, _ in
                            feedbackManager.lightHaptic()
                        }
                }
                
                Divider()
                
                // Language Selection
                Button(action: { 
                    feedbackManager.buttonTap()
                    showingLanguageSheet = true 
                }) {
                    HStack(spacing: 16) {
                        // Language icon with background
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.blue.opacity(0.2), .purple.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "globe")
                                .foregroundColor(.blue)
                                .font(.system(size: 16, weight: .medium))
                        }
                        
                        // Language info
                        VStack(alignment: .leading, spacing: 2) {
                            Text("settings.general.language".localized)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Text(currentLanguageDisplayName)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Current language flag
                        Text(getCurrentLanguageFlag())
                            .font(.system(size: 20))
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(Color.secondary.opacity(0.6))
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                
                // Notifications
                HStack {
                    Label("settings.general.notifications".localized, systemImage: "bell.fill")
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { settingsManager.notificationsEnabled },
                        set: { newValue in
                            if newValue {
                                requestNotificationPermission()
                            } else {
                                settingsManager.notificationsEnabled = false
                                cancelAllNotifications()
                            }
                        }
                    ))
                    .tint(.purple)
                }
                
                Divider()
                
                // Haptic Feedback
                HStack {
                    Label("settings.general.haptic_feedback".localized, systemImage: "iphone.radiowaves.left.and.right")
                    Spacer()
                    Toggle("", isOn: $feedbackManager.hapticFeedbackEnabled)
                        .tint(.purple)
                        .onChange(of: feedbackManager.hapticFeedbackEnabled) { _, newValue in
                            if newValue {
                                feedbackManager.lightHaptic()
                            }
                        }
                }
                
            }
        }
    }
    
    // MARK: - Habits Section
    @ViewBuilder
    private var habitsSection: some View {
        SettingsCard(title: "settings.habits.title".localized, icon: "checkmark.circle") {
            VStack(spacing: 16) {
                // Streak Info Display
                HStack {
                    Label("settings.habits.show_streak_info".localized, systemImage: "chart.line.uptrend.xyaxis")
                    Spacer()
                    Toggle("", isOn: $settingsManager.showStreakInfo)
                    .tint(.purple)
                }
             
            }
        }
    }
    
    // MARK: - Health Section
    @ViewBuilder
    private var healthSection: some View {
        SettingsCard(title: "settings.health.title".localized, icon: "heart.fill") {
            VStack(spacing: 16) {
                // Daily Water Goal
                VStack(alignment: .leading, spacing: 12) {
                    Label("settings.health.water.goal".localized, systemImage: "drop.fill")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(waterGoalOptions, id: \.self) { goal in
                            Button(action: {
                                settingsManager.dailyWaterGoal = goal
                                feedbackManager.lightHaptic()
                            }) {
                                VStack(spacing: 4) {
                                    Text("\(goal)")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                    Text("ml")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(height: 50)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(settingsManager.dailyWaterGoal == goal ? Color.purple : Color.gray.opacity(0.15))
                                )
                                .foregroundColor(settingsManager.dailyWaterGoal == goal ? .white : .primary)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Memory Game Section
    @ViewBuilder
    private var memoryGameSection: some View {
        SettingsCard(title: NSLocalizedString("settings.memory.title", comment: "Memory Game"), icon: "brain.head.profile") {
            VStack(spacing: 16) {
                // Default Grid Size
                VStack(alignment: .leading, spacing: 8) {
                    Label(NSLocalizedString("settings.memory.grid.size", comment: "Default Grid Size"), systemImage: "grid")
                    
                    if !gridSizeOptions.isEmpty {
                        Picker("", selection: Binding(
                            get: { 
                                gridSizeOptions.contains(settingsManager.memoryGameDefaultSize) ? 
                                settingsManager.memoryGameDefaultSize : gridSizeOptions.first ?? 4
                            },
                            set: { newValue in
                                if gridSizeOptions.contains(newValue) {
                                    settingsManager.memoryGameDefaultSize = newValue
                                    feedbackManager.lightHaptic()
                                }
                            }
                        )) {
                            ForEach(gridSizeOptions, id: \.self) { size in
                                Text("\(size)×\(size)").tag(size)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    } else {
                        Text("No grid options available")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Privacy Section
    @ViewBuilder
    private var privacySection: some View {
        SettingsCard(title: "settings.privacy.title".localized, icon: "lock.shield") {
            VStack(spacing: 16) {
                Button(action: {
                    feedbackManager.buttonTap()
                    showingExportFormatAlert = true
                }) {
                    HStack {
                        Label("settings.privacy.data.export".localized, systemImage: "square.and.arrow.up")
                        Spacer()
                        
                        if isExporting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.secondary)
                        } else {
                            Button(action: {
                                feedbackManager.buttonTap()
                                showingExportFormatAlert = true
                            }) {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .disabled(isExporting)
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                
                Button(action: {
                    feedbackManager.warningHaptic()
                    showingDeleteConfirmation = true
                }) {
                    HStack {
                        Label("settings.privacy.data.delete".localized, systemImage: "trash")
                            .foregroundColor(.red)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - About Section
    @ViewBuilder
    private var aboutSection: some View {
        SettingsCard(title: "settings.about.title".localized, icon: "info.circle") {
            VStack(spacing: 16) {
                Button(action: { showingAbout = true }) {
                    HStack {
                        Label("settings.about.app".localized, systemImage: "app.badge")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                
                Divider()
                
                Button(action: { openSupportEmail() }) {
                    HStack {
                        Label("settings.about.support".localized, systemImage: "questionmark.circle")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Language Selection Sheet
    @ViewBuilder
    private var languageSelectionSheet: some View {
        NavigationStack {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.08),
                        Color.purple.opacity(0.06),
                        Color.pink.opacity(0.04),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Header description
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "globe")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                                Text("settings.language.description".localized)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        // Language options
                        ForEach(languages, id: \.0) { code, englishName, turkishName in
                            languageOptionCard(
                                code: code,
                                englishName: englishName,
                                turkishName: turkishName
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("settings.language.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.done".localized) {
                        showingLanguageSheet = false
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.blue)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Language Option Card
    @ViewBuilder
    private func languageOptionCard(code: String, englishName: String, turkishName: String) -> some View {
        Button(action: {
            // Update settings first
            settingsManager.selectedLanguage = code
            
            // Update language manager (this will trigger UI refresh)
            languageManager.currentLanguage = code
            
            showingLanguageSheet = false
            feedbackManager.successHaptic()
            
            // Force complete UI refresh
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                languageManager.objectWillChange.send()
                settingsManager.objectWillChange.send()
            }
        }) {
            HStack(spacing: 16) {
                // Language flag/icon
                Text(getLanguageFlag(for: code))
                    .font(.system(size: 32))
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )
                
                // Language info
                VStack(alignment: .leading, spacing: 4) {
                    Text(settingsManager.selectedLanguage == "tr" ? turkishName : englishName)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(getLanguageSubtitle(for: code))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Selection indicator
                ZStack {
                    Circle()
                        .fill(settingsManager.selectedLanguage == code ? Color.blue : Color.clear)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(settingsManager.selectedLanguage == code ? Color.blue : Color.secondary.opacity(0.3), lineWidth: 2)
                        )
                    
                    if settingsManager.selectedLanguage == code {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                settingsManager.selectedLanguage == code 
                                ? LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: settingsManager.selectedLanguage == code ? 2 : 0
                            )
                    )
            )
            .scaleEffect(settingsManager.selectedLanguage == code ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: settingsManager.selectedLanguage == code)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Language Helpers
    private func getLanguageFlag(for code: String) -> String {
        switch code {
        case "system":
            return "🌐"
        case "en":
            return "🇺🇸"
        case "tr":
            return "🇹🇷"
        default:
            return "🌐"
        }
    }
    
    private func getLanguageSubtitle(for code: String) -> String {
        switch code {
        case "system":
            return "settings.language.system.subtitle".localized
        case "en":
            return "English (United States)"
        case "tr":
            return "Turkish (Türkiye)"
        default:
            return ""
        }
    }
    
    private func getCurrentLanguageFlag() -> String {
        return getLanguageFlag(for: settingsManager.selectedLanguage)
    }
    
    // MARK: - About Sheet
    @ViewBuilder
    private var aboutSheet: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App Icon
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.red)
                    
                    VStack(spacing: 8) {
                        Text("Life Companion")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("settings.about.version".localized + " 1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 8) {
                        Text("settings.about.description".localized)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .font(.body)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.regularMaterial)
                    )
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("settings.about.features".localized)
                            .font(.headline)
                        
                        FeatureRow(icon: "target", title: "settings.about.feature.habits".localized)
                        FeatureRow(icon: "heart.fill", title: "settings.about.feature.health".localized)
                        FeatureRow(icon: "brain", title: "settings.about.feature.memory".localized)
                        FeatureRow(icon: "checklist", title: "settings.about.feature.todos".localized)
                        FeatureRow(icon: "leaf.fill", title: "settings.about.feature.meditation".localized)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.regularMaterial)
                    )
                }
                .padding()
            }
            .navigationTitle("settings.about.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.done".localized) {
                        showingAbout = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Views
    private struct FeatureRow: View {
        let icon: String
        let title: String
        
        var body: some View {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: icon)
                        .foregroundColor(.blue)
                        .font(.system(size: 14, weight: .semibold))
                }
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Helper Properties
    private var currentLanguageDisplayName: String {
        if let language = languages.first(where: { $0.0 == languageManager.currentLanguage }) {
            return languageManager.currentLanguage == "tr" ? language.2 : language.1
        }
        return "System Default"
    }
    
    // MARK: - Helper Methods
    private func loadTimeDefaults() {
        autoResetTime = settingsManager.autoResetTime
    }
    
    private func saveTime(_ time: Date, isReminderTime: Bool) {
        settingsManager.autoResetTime = time
        feedbackManager.lightHaptic()
        
        // Notify HealthViewModel about reset time change
        NotificationCenter.default.post(
            name: NSNotification.Name("ResetTimeUpdated"),
            object: modelContext,
            userInfo: ["newResetTime": time]
        )
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    settingsManager.notificationsEnabled = true
                    feedbackManager.successHaptic()
                } else {
                    showingNotificationPermissionAlert = true
                    feedbackManager.errorHaptic()
                }
            }
        }
    }
    
    private func exportUserData(format: ExportFormat = .pdf) {
        // Immediate feedback for better UX
        feedbackManager.buttonTap()
        
        // Show loading state immediately
        isExporting = true
        
        // Run export in background to avoid UI blocking
        Task {
            let context = modelContext
            let result = await Task.detached(priority: .userInitiated) {
                return dataManager.exportUserData(context: context, format: format)
            }.value
            
            // Update UI on main thread
            await MainActor.run {
                // Hide loading state
                isExporting = false
                
                if let url = result {
                    // Verify file exists
                    if FileManager.default.fileExists(atPath: url.path) {
                        showShareSheet(url: url)
                        feedbackManager.successHaptic()
                    } else {
                        showingExportError = true
                        feedbackManager.errorHaptic()
                    }
                } else {
                    showingExportError = true
                    feedbackManager.errorHaptic()
                }
            }
        }
    }
    
    private func showShareSheet(url: URL) {
        
        // Ensure we're on main thread for UI operations
        DispatchQueue.main.async {
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            activityVC.excludedActivityTypes = [
                .assignToContact,
                .saveToCameraRoll,
                .postToFlickr,
                .postToVimeo
            ]
            
            // iPad support
            if let popover = activityVC.popoverPresentationController,
               let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                popover.sourceView = window.rootViewController?.view
                popover.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            // Find the topmost presented view controller
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let rootVC = window.rootViewController else {
                self.showingExportError = true
                return
            }
            
            var presentingVC = rootVC
            while let presentedVC = presentingVC.presentedViewController {
                presentingVC = presentedVC
            }
            
            presentingVC.present(activityVC, animated: true)
        }
    }
    
    private func deleteAllData() {
        do {
            try dataManager.deleteAllUserData(context: modelContext)
            feedbackManager.successHaptic()
            // Optionally dismiss settings or show success message
        } catch {
            feedbackManager.errorHaptic()
        }
    }
    
    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        feedbackManager.successHaptic()
    }
}

// MARK: - Settings Card Component
struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.purple)
                    .font(.title3)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Document Picker for Saving Files  


// MARK: - Share Sheet for Data Export
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        
        for (index, item) in activityItems.enumerated() {
            if let url = item as? URL {
                
                if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                   let size = attributes[.size] as? Int {
                }
            } else {
            }
        }
        
        let activityController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        // Exclude some activities if needed
        activityController.excludedActivityTypes = [
            .assignToContact,
            .saveToCameraRoll,
            .postToFlickr,
            .postToVimeo
        ]
        
        return activityController
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - SettingsView Helper Methods Extension
extension SettingsView {
    private func openSupportEmail() {
        feedbackManager.buttonTap()
        
        // Check if we're in simulator first
        #if targetEnvironment(simulator)
        DispatchQueue.main.async {
            self.showingEmailAlert = true
        }
        return
        #endif
        
        let email = "gayeugur00@gmail.com"
        let subject = "LifeCompanion App - Help & Support"
        let body = """
        Hello LifeCompanion Support Team,
        
        I need assistance with the LifeCompanion app.
        
        Device Information:
        - iOS Version: \(UIDevice.current.systemVersion)
        - Device: \(UIDevice.current.model)
        - App Version: \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
        
        Issue Description:
        [Please describe your issue here]
        
        Best regards
        """
        
        // URL encode all parameters properly
        guard let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            DispatchQueue.main.async {
                self.showingEmailAlert = true
            }
            return
        }
        
        // Multiple Gmail URL schemes to try
        let gmailSchemes = [
            "googlegmail:///co?to=\(encodedEmail)&subject=\(encodedSubject)&body=\(encodedBody)",
            "googlegmail://co?to=\(encodedEmail)&subject=\(encodedSubject)&body=\(encodedBody)",
            "gmail://co?to=\(encodedEmail)&subject=\(encodedSubject)&body=\(encodedBody)"
        ]
        
        // Try each Gmail scheme
        for (index, urlString) in gmailSchemes.enumerated() {
            
            if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url) { success in
                    DispatchQueue.main.async {
                        if success {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                        } else {
                            self.showingEmailAlert = true
                        }
                    }
                }
                return
            }
        }
        
        
        // Try other email clients
        let emailClients = [
            ("Outlook", "ms-outlook://compose?to=\(encodedEmail)&subject=\(encodedSubject)&body=\(encodedBody)"),
            ("Spark", "readdle-spark://compose?recipient=\(encodedEmail)&subject=\(encodedSubject)&body=\(encodedBody)"),
            ("Yahoo Mail", "ymail://mail/compose?to=\(encodedEmail)&subject=\(encodedSubject)&body=\(encodedBody)")
        ]
        
        for (clientName, urlString) in emailClients {
            if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url) { success in
                    DispatchQueue.main.async {
                        if success {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                        } else {
                            self.showingEmailAlert = true
                        }
                    }
                }
                return
            }
        }
        
        // Final fallback to default Mail app
        let mailURLString = "mailto:\(encodedEmail)?subject=\(encodedSubject)&body=\(encodedBody)"
        
        if let mailURL = URL(string: mailURLString) {
            UIApplication.shared.open(mailURL) { success in
                DispatchQueue.main.async {
                    if success {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                    } else {
                        self.showingEmailAlert = true
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                self.showingEmailAlert = true
            }
        }
    }
}
