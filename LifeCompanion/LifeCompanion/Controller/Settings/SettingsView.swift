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
    @State private var showingExportSheet = false
    @State private var showingDocumentPicker = false
    @State private var exportURL: URL?
    @State private var exportFormat: ExportFormat = .json
    @State private var showingEmailAlert = false
    @State private var showingExportFormatAlert = false
    @State private var showingExportFailedAlert = false
    @State private var showingSuccessAlert = false
    @State private var selectedExportFormat: ExportFormat = .pdf
    
    private let languages = [
        ("system", "🌐 System Default", "Sistem Varsayılanı"),
        ("en", "🇺🇸 English", "English"),
        ("tr", "🇹🇷 Türkçe", "Türkçe")
    ]
    
    private let waterGoalOptions = [1500, 2000, 2500, 3000, 3500, 4000]
    private let gridSizeOptions = [3, 4, 5, 6]
    
    var body: some View {
        NavigationView {
            settingsContent
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            print("⚙️ SettingsView appeared")
        }
        .sheet(isPresented: $showingExportSheet) {
            exportOptionsSheet
        }
        .sheet(isPresented: $showingDocumentPicker) {
            documentPickerSheet
        }
        .alert(LanguageManager.shared.getLocalizedString(for: "settings.export.format.title"), isPresented: $showingExportFormatAlert) {
            exportFormatAlert
        } message: {
            Text("settings.export.format.message".localized)
        }
        .alert("Export Failed", isPresented: $showingExportFailedAlert) {
            Button("common.ok".localized, role: .cancel) { }
        } message: {
            Text("Unable to export your data. Please try again or contact support if the issue persists.")
        }
        .alert(LanguageManager.shared.getLocalizedString(for: "success"), isPresented: $showingSuccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(LanguageManager.shared.getLocalizedString(for: "export_success_message"))
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
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
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
                .padding(.bottom, 30)
            }
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
    private var exportOptionsSheet: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text(LanguageManager.shared.getLocalizedString(for: "choose_export_method"))
                    .font(.headline)
                
                Text("Select how you want to save your data export")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top)
            
            VStack(spacing: 12) {
                Button(action: {
                    print("🔄 User selected 'Save to Files'")
                    showingExportSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showingDocumentPicker = true
                    }
                }) {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "folder.fill")
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(LanguageManager.shared.getLocalizedString(for: "save_to_files"))
                                    .font(.headline)
                                Text("Save directly to Files app")
                                    .font(.caption)
                                    .opacity(0.8)
                            }
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                Button(action: {
                    print("🔄 User selected 'Share'")
                    showingExportSheet = false
                    if let url = exportURL {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showShareSheet(url: url)
                        }
                    }
                }) {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "square.and.arrow.up.fill")
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(LanguageManager.shared.getLocalizedString(for: "share"))
                                    .font(.headline)
                                Text("Share via AirDrop, Email, etc.")
                                    .font(.caption)
                                    .opacity(0.8)
                            }
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            
            Button("Cancel") {
                showingExportSheet = false
            }
            .foregroundColor(.secondary)
            .padding(.top, 8)
            
            Spacer()
        }
        .padding()
        .presentationDetents([.height(300)])
    }
    
    @ViewBuilder
    private var documentPickerSheet: some View {
        if let url = exportURL {
            DocumentPicker(
                sourceURL: url,
                exportFormat: exportFormat,
                onSuccess: { savedURL in
                    print("✅ File saved successfully to: \(savedURL)")
                    feedbackManager.successHaptic()
                    DispatchQueue.main.async {
                        showingSuccessAlert = true
                    }
                },
                onError: { error in
                    print("❌ Document picker error: \(error)")
                    feedbackManager.errorHaptic()
                    DispatchQueue.main.async {
                        showingExportFailedAlert = true
                    }
                }
            )
        }
    }
    
    @ViewBuilder 
    private var exportFormatAlert: some View {
        Button(LanguageManager.shared.getLocalizedString(for: "settings.export.format.pdf")) {
            selectedExportFormat = .pdf
            exportUserData(format: .pdf)
        }
        Button(LanguageManager.shared.getLocalizedString(for: "settings.export.format.json")) {
            selectedExportFormat = .json
            exportUserData(format: .json)
        }
        Button("common.cancel".localized, role: .cancel) { }
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
        .alert("settings.export.format.title".localized, isPresented: $showingExportFormatAlert) {
            Button("settings.export.format.pdf".localized) {
                selectedExportFormat = .pdf
                exportUserData(format: .pdf)
            }
            Button("settings.export.format.json".localized) {
                selectedExportFormat = .json
                exportUserData(format: .json)
            }
            Button("common.cancel".localized, role: .cancel) { }
        } message: {
            Text("settings.export.format.message".localized)
        }
        .alert("Export Failed", isPresented: $showingExportFailedAlert) {
            Button("common.ok".localized, role: .cancel) { }
        } message: {
            Text("Unable to export your data. Please try again or contact support if the issue persists.")
        }
        .alert(LanguageManager.shared.getLocalizedString(for: "success"), isPresented: $showingSuccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(LanguageManager.shared.getLocalizedString(for: "export_success_message"))
        }
    }
    
    // MARK: - Header Section
    @ViewBuilder
    private var headerSection: some View {
        HStack {
            Text("menu.settings".localized)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
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
                    HStack {
                        Label("settings.general.language".localized, systemImage: "globe")
                        Spacer()
                        Text(currentLanguageDisplayName)
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
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
                            }
                        }
                    ))
                    .tint(.purple)
                }
                
                Divider()
                
                // Sound Effects
                HStack {
                    Label("settings.general.sounds".localized, systemImage: "speaker.wave.2.fill")
                    Spacer()
                    Toggle("", isOn: $feedbackManager.soundEffectsEnabled)
                        .tint(.purple)
                        .onChange(of: feedbackManager.soundEffectsEnabled) { _, newValue in
                            if newValue { feedbackManager.playSound(.click) }
                        }
                }
                
                Divider()
                
                // Haptic Feedback
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Label("settings.general.haptics".localized, systemImage: "iphone.radiowaves.left.and.right")
                        Spacer()
                        Toggle("", isOn: $feedbackManager.hapticFeedbackEnabled)
                            .tint(.purple)
                            .onChange(of: feedbackManager.hapticFeedbackEnabled) { _, newValue in
                                if newValue { feedbackManager.mediumHaptic() }
                            }
                    }
                    Text("settings.general.haptics.description".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Habits Section
    @ViewBuilder
    private var habitsSection: some View {
        SettingsCard(title: "settings.habits.title".localized, icon: "checkmark.circle") {
            VStack(spacing: 16) {
                // Streak Celebrations
                HStack {
                    Label("settings.habits.celebrations".localized, systemImage: "party.popper")
                    Spacer()
                    Toggle("", isOn: $settingsManager.streakCelebrationEnabled)
                        .tint(.purple)
                }
                
                Divider()
                
                // Auto Reset Time
                VStack(alignment: .leading, spacing: 8) {
                    Label("settings.habits.reset.time".localized, systemImage: "arrow.clockwise")
                    DatePicker("", selection: $autoResetTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
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
                                        .fill(settingsManager.dailyWaterGoal == goal ? Color.blue : Color.gray.opacity(0.15))
                                )
                                .foregroundColor(settingsManager.dailyWaterGoal == goal ? .white : .primary)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Memory Game Section
    @ViewBuilder
    private var memoryGameSection: some View {
        SettingsCard(title: "settings.memory.title".localized, icon: "brain.head.profile") {
            VStack(spacing: 16) {
                // Default Grid Size
                VStack(alignment: .leading, spacing: 8) {
                    Label("settings.memory.grid.size".localized, systemImage: "grid")
                    
                    Picker("", selection: $settingsManager.memoryGameDefaultSize) {
                        ForEach(gridSizeOptions, id: \.self) { size in
                            Text("\(size)×\(size)").tag(size)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: settingsManager.memoryGameDefaultSize) { _, _ in
                        feedbackManager.lightHaptic()
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
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
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
                
                Button(action: {}) {
                    HStack {
                        Label("settings.about.privacy".localized, systemImage: "doc.text")
                        Spacer()
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
        NavigationView {
            List {
                ForEach(languages, id: \.0) { code, englishName, turkishName in
                    Button(action: {
                        // Update settings first
                        settingsManager.selectedLanguage = code
                        
                        // Update language manager (this will trigger UI refresh)
                        languageManager.currentLanguage = code
                        
                        showingLanguageSheet = false
                        feedbackManager.successHaptic()
                        
                        print("🌍 Language changed from Settings to: \(code)")
                        
                        // Force complete UI refresh
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            languageManager.objectWillChange.send()
                            settingsManager.objectWillChange.send()
                        }
                    }) {
                        HStack {
                            Text(settingsManager.selectedLanguage == "tr" ? turkishName : englishName)
                                .foregroundColor(.primary)
                            Spacer()
                            if settingsManager.selectedLanguage == code {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("settings.language.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.done".localized) {
                        showingLanguageSheet = false
                    }
                }
            }
        }
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
                        Text("LifeCompanion")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("settings.about.version".localized + " 1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Text("settings.about.description".localized)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("settings.about.features".localized)
                            .font(.headline)
                        
                        FeatureRow(icon: "checkmark.circle", title: "settings.about.feature.habits".localized)
                        FeatureRow(icon: "heart.fill", title: "settings.about.feature.health".localized)
                        FeatureRow(icon: "brain.head.profile", title: "settings.about.feature.memory".localized)
                        FeatureRow(icon: "list.bullet", title: "settings.about.feature.todos".localized)
                        FeatureRow(icon: "om", title: "settings.about.feature.meditation".localized)
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
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 20)
                Text(title)
                    .font(.subheadline)
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
        if let encoded = try? JSONEncoder().encode(time) {
            autoResetTimeData = encoded
        }
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
        print("🔄 Starting export from SettingsView in \(format.rawValue) format...")
        feedbackManager.buttonTap()
        
        // Store format for document picker
        self.exportFormat = format
        
        // Add small delay to ensure UI updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            do {
                if let url = dataManager.exportUserData(context: modelContext, format: format) {
                    print("✅ Export successful from SettingsView: \(url)")
                    
                    // Verify file exists before showing options
                    if FileManager.default.fileExists(atPath: url.path) {
                        exportURL = url
                        showingExportSheet = true
                        feedbackManager.successHaptic()
                        print("📤 Showing export options for file: \(url.lastPathComponent)")
                    } else {
                        print("❌ Export file does not exist at path: \(url.path)")
                        feedbackManager.errorHaptic()
                        self.showingExportFailedAlert = true
                    }
                } else {
                    print("❌ Export failed from SettingsView - nil URL returned")
                    feedbackManager.errorHaptic()
                    self.showingExportFailedAlert = true
                }
            } catch {
                print("❌ Export error from SettingsView: \(error)")
                feedbackManager.errorHaptic()
                self.showingExportFailedAlert = true
            }
        }
    }
    
    private func showShareSheet(url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityVC.excludedActivityTypes = [
            .assignToContact,
            .saveToCameraRoll,
            .postToFlickr,
            .postToVimeo
        ]
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            
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
            print("❌ Delete error: \(error)")
        }
    }
    
    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
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
struct DocumentPicker: UIViewControllerRepresentable {
    let sourceURL: URL
    let exportFormat: ExportFormat
    let onSuccess: (URL) -> Void
    let onError: (Error) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        print("📁 Creating DocumentPicker for format: \(exportFormat.rawValue)")
        print("📄 Source file: \(sourceURL.lastPathComponent)")
        
        // Copy file to a more accessible location first
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "LifeCompanion_Export_\(dateFormatter.string(from: Date())).\(exportFormat.fileExtension)"
        let destinationURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            // Remove existing file if it exists
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            
            // Copy the exported file to documents directory
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            print("✅ File copied to documents: \(destinationURL.path)")
            
            // Create picker for the copied file
            let picker = UIDocumentPickerViewController(forExporting: [destinationURL])
            picker.delegate = context.coordinator
            picker.allowsMultipleSelection = false
            picker.shouldShowFileExtensions = true
            
            return picker
            
        } catch {
            print("❌ Failed to copy file: \(error)")
            // Fallback to original file
            let picker = UIDocumentPickerViewController(forExporting: [sourceURL])
            picker.delegate = context.coordinator
            picker.allowsMultipleSelection = false
            picker.shouldShowFileExtensions = true
            
            return picker
        }
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            print("✅ Document picker completed successfully")
            guard let url = urls.first else {
                print("❌ No URL selected in document picker")
                parent.onError(DocumentPickerError.noURLSelected)
                return
            }
            
            print("📂 File saved to: \(url.path)")
            print("📂 File name: \(url.lastPathComponent)")
            parent.onSuccess(url)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            print("⏹️ Document picker was cancelled")
            parent.onError(DocumentPickerError.cancelled)
        }
    }
}

enum DocumentPickerError: LocalizedError {
    case noURLSelected
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .noURLSelected:
            return "No file location was selected"
        case .cancelled:
            return "File saving was cancelled"
        }
    }
}

// MARK: - Share Sheet for Data Export
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        print("📤 Creating UIActivityViewController with \(activityItems.count) items")
        
        for (index, item) in activityItems.enumerated() {
            if let url = item as? URL {
                print("   📄 Item \(index): URL - \(url.lastPathComponent)")
                print("       Path: \(url.path)")
                print("       Exists: \(FileManager.default.fileExists(atPath: url.path))")
                
                if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                   let size = attributes[.size] as? Int {
                    print("       Size: \(size) bytes")
                }
            } else {
                print("   📄 Item \(index): \(type(of: item))")
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
        print("🔄 Opening support email...")
        feedbackManager.buttonTap()
        
        // Check if we're in simulator first
        #if targetEnvironment(simulator)
        print("⚠️ Running in simulator - showing contact information")
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
            print("❌ Failed to encode email parameters")
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
            print("📧 Trying Gmail scheme \(index + 1): \(urlString)")
            
            if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
                print("✅ Opening Gmail app with scheme \(index + 1)...")
                UIApplication.shared.open(url) { success in
                    DispatchQueue.main.async {
                        if success {
                            print("✅ Gmail opened successfully")
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                        } else {
                            print("❌ Gmail failed to open despite being available")
                            self.showingEmailAlert = true
                        }
                    }
                }
                return
            }
        }
        
        print("❌ Gmail app not available, trying other email clients...")
        
        // Try other email clients
        let emailClients = [
            ("Outlook", "ms-outlook://compose?to=\(encodedEmail)&subject=\(encodedSubject)&body=\(encodedBody)"),
            ("Spark", "readdle-spark://compose?recipient=\(encodedEmail)&subject=\(encodedSubject)&body=\(encodedBody)"),
            ("Yahoo Mail", "ymail://mail/compose?to=\(encodedEmail)&subject=\(encodedSubject)&body=\(encodedBody)")
        ]
        
        for (clientName, urlString) in emailClients {
            if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
                print("✅ Opening \(clientName)...")
                UIApplication.shared.open(url) { success in
                    DispatchQueue.main.async {
                        if success {
                            print("✅ \(clientName) opened successfully")
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                        } else {
                            print("❌ \(clientName) failed to open")
                            self.showingEmailAlert = true
                        }
                    }
                }
                return
            }
        }
        
        // Final fallback to default Mail app
        let mailURLString = "mailto:\(encodedEmail)?subject=\(encodedSubject)&body=\(encodedBody)"
        print("📧 Final fallback to Mail app: \(mailURLString)")
        
        if let mailURL = URL(string: mailURLString) {
            print("✅ Opening default Mail app...")
            UIApplication.shared.open(mailURL) { success in
                DispatchQueue.main.async {
                    if success {
                        print("✅ Mail app opened successfully")
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                    } else {
                        print("❌ Failed to open Mail app")
                        self.showingEmailAlert = true
                    }
                }
            }
        } else {
            print("❌ Could not create mailto URL")
            DispatchQueue.main.async {
                self.showingEmailAlert = true
            }
        }
    }
    

}

#Preview {
    SettingsView()
}
