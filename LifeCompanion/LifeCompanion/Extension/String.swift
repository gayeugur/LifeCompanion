//
//  String.swift
//  LifeCompanion
//
//  Created by gayeugur on 2.11.2025.
//

import Foundation

extension String {
    var localized: String { 
        LanguageManager.shared.getLocalizedString(for: self)
    }
    
    func localized(comment: String = "") -> String {
        LanguageManager.shared.getLocalizedString(for: self, comment: comment)
    }
}
