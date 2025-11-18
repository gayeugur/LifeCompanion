//
//  HighScoresView.swift
//  LifeCompanion
//
//  Created on 7.11.2025.
//

import SwiftUI

struct HighScoresView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let gridSizes = [3, 4, 5, 6]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Orange gradient background matching Memory Game theme
                LinearGradient(
                    colors: [
                        Color.orange.opacity(0.08),
                        Color.orange.opacity(0.04),
                        Color.yellow.opacity(0.02),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("🏆")
                            .font(.system(size: 50))
                        Text("High Scores")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("coming.soon".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    Text("High scores functionality will be available in a future update.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding()
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("High Scores")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
