//
//  SimpleMemoryGameView.swift
//  LifeCompanion
//
//  Created on 06.11.2025.
//

import SwiftUI

struct SimpleMemoryGameView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("🧠")
                .font(.system(size: 60))
            
            Text("Memory Game")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Coming Soon!")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Button("Start Game") {
                // TODO: Add game logic
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("Memory Game")
        .navigationBarTitleDisplayMode(.large)
    }
}