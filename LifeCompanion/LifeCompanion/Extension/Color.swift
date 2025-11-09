//
//  Color.swift
//  LifeCompanion
//
//  Created by gayeugur on 2.11.2025.
//

import SwiftUI
import UIKit

extension Color {
    static let customGreen = Color(.sRGB,
                                   red: 0x4C/255,
                                   green: 0x76/255,
                                   blue: 0x3B/255)
    
    // MARK: - Theme Adaptive Colors
    
    /// Primary background color that adapts to light/dark mode
    static var primaryBackground: Color {
        Color(UIColor.systemBackground)
    }
    
    /// Secondary background color for cards and sections
    static var secondaryBackground: Color {
        Color(UIColor.secondarySystemBackground)
    }
    
    /// Tertiary background color for subtle elements
    static var tertiaryBackground: Color {
        Color(UIColor.tertiarySystemBackground)
    }
    
    /// Primary text color
    static var primaryText: Color {
        Color(UIColor.label)
    }
    
    /// Secondary text color
    static var secondaryText: Color {
        Color(UIColor.secondaryLabel)
    }
    
    /// Tertiary text color for subtle text
    static var tertiaryText: Color {
        Color(UIColor.tertiaryLabel)
    }
    
    /// Adaptive border color
    static var borderColor: Color {
        Color(UIColor.separator)
    }
    
    /// Adaptive fill color for buttons and interactive elements
    static var fillColor: Color {
        Color(UIColor.systemFill)
    }
    
    /// Success color that works in both modes
    static var successColor: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark 
            ? UIColor.systemGreen.withAlphaComponent(0.8)
            : UIColor.systemGreen
        })
    }
    
    /// Warning color that works in both modes
    static var warningColor: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark 
            ? UIColor.systemOrange.withAlphaComponent(0.8)
            : UIColor.systemOrange
        })
    }
    
    /// Error color that works in both modes
    static var errorColor: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark 
            ? UIColor.systemRed.withAlphaComponent(0.8)
            : UIColor.systemRed
        })
    }
    
    /// Accent purple gradient colors
    static var accentGradient: [Color] {
        [
            Color.purple.opacity(0.6),
            Color.blue.opacity(0.4),
            Color.indigo.opacity(0.3)
        ]
    }
    
    /// Card background with subtle shadow effect
    static var cardBackground: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark 
            ? UIColor.secondarySystemBackground
            : UIColor.systemBackground
        })
    }
}
