//
//  Untitled.swift
//  LifeCompanion
//
//  Created by gayeugur on 24.11.2025.
//

import Foundation

extension Bundle {
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
    }
    
    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "N/A"
    }
}
