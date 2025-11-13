//
//  MigrationHelper.swift
//  LifeCompanion
//
//  Created on 7.11.2025.
//

import Foundation
import SwiftData

class MigrationHelper {
    static func clearDataIfNeeded() {
        let hasRunBefore = UserDefaults.standard.bool(forKey: "hasRunStreakMigration")
        
        if !hasRunBefore {
            // Clear existing data for clean migration
            let url = URL.applicationSupportDirectory.appending(path: "default.store")
            try? FileManager.default.removeItem(at: url)
            
            UserDefaults.standard.set(true, forKey: "hasRunStreakMigration")
        }
    }
}