//
//  MenuItem.swift
//  LifeCompanion
//
//  Created by gayeugur on 25.10.2025.
//

import Foundation
import SwiftUICore

// MARK: - Models
struct MenuItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
}
