//
//  LanguageManager.swift
//  LifeCompanion
//
//  Created on 8.11.2025.
//

import SwiftUI
import Foundation

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: String = "system" {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "selectedLanguage")
            setAppLanguage()
        }
    }
    
    private init() {
        // Get stored language preference
        let storedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "system"
        currentLanguage = storedLanguage
        
        print("🌍 LanguageManager initialized with language: \(storedLanguage)")
        
        // FOR TESTING: Force Turkish to test localization
        // Uncomment next line to test Turkish
        // currentLanguage = "tr"
        
        setAppLanguage()
    }
    
    private func setAppLanguage() {
        let language = currentLanguage == "system" ? getSystemLanguage() : currentLanguage
        
        // Store the selected language
        UserDefaults.standard.set(language, forKey: "AppLanguage")
        UserDefaults.standard.synchronize()
        
        print("🌍 Language changed to: \(language)")
        
        // Force UI refresh with objectWillChange
        DispatchQueue.main.async {
            self.objectWillChange.send()
            NotificationCenter.default.post(name: .languageDidChange, object: language)
        }
    }
    
    private func getSystemLanguage() -> String {
        let systemLang = Locale.preferredLanguages.first?.components(separatedBy: "-").first ?? "en"
        print("🌍 System language: \(systemLang)")
        return systemLang
    }
    
    func updateSystemLanguage() {
        if currentLanguage == "system" {
            setAppLanguage()
        }
    }
    
    func getLocalizedString(for key: String, comment: String = "") -> String {
        let language = currentLanguage == "system" ? getSystemLanguage() : currentLanguage
        
        print("🌍 Looking for key '\(key)' in language '\(language)'")
        
        // First try to get the selected language bundle
        if let path = Bundle.main.path(forResource: language, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            let localizedString = bundle.localizedString(forKey: key, value: nil, table: nil)
            print("🌍 Found in \(language): '\(localizedString)'")
            if localizedString != key {
                return localizedString
            }
        }
        
        // Fallback to English if not found in selected language
        if let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
           let bundle = Bundle(path: path) {
            let localizedString = bundle.localizedString(forKey: key, value: nil, table: nil)
            print("🌍 Fallback to English: '\(localizedString)'")
            if localizedString != key {
                return localizedString
            }
        }
        
        // Return the key itself if no localization found
        print("🌍 No localization found for '\(key)', returning key")
        return key
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let languageDidChange = Notification.Name("languageDidChange")
}

// MARK: - Environment Key
struct LanguageManagerKey: EnvironmentKey {
    static let defaultValue = LanguageManager.shared
}

extension EnvironmentValues {
    var languageManager: LanguageManager {
        get { self[LanguageManagerKey.self] }
        set { self[LanguageManagerKey.self] = newValue }
    }
}