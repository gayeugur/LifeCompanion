//
//  GameSettingsView.swift
//  LifeCompanion
//
//  Created on 06.11.2025.
//

import SwiftUI

struct GameSettingsView: View {
    @ObservedObject var viewModel: MemoryGameViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var languageManager: LanguageManager
    
    @State private var showingConfirmation = false
    @State private var refreshKey = UUID()
    
    var body: some View {
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
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("memory.settings.title".localized)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("memory.settings.description".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Game Mode Selection
                    gameModeSection
                    
                    // Grid Size Selection
                    gridSizeSection
                    
                    // Current Game Info
                    if viewModel.isGameActive {
                        currentGameInfo
                    }
                    
                    // Best Scores
                    bestScoreSection
                    
                    Spacer()
                }
                .padding()
            }
        }
        .navigationTitle("memory.settings.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("common.cancel".localized) {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("common.save".localized) {
                    if viewModel.isGameActive {
                        showingConfirmation = true
                    } else {
                        applySettings()
                    }
                }
            }
        }
        .alert("memory.settings.confirm.title".localized, isPresented: $showingConfirmation) {
            Button("memory.settings.new.game".localized, role: .destructive) {
                applySettings()
            }
            Button("common.cancel".localized, role: .cancel) { }
        } message: {
            Text("memory.settings.confirm.message".localized)
        }
        .id(refreshKey)
        .onReceive(NotificationCenter.default.publisher(for: .languageDidChange)) { _ in
            refreshKey = UUID()
        }
    }
    
    // MARK: - Game Mode Section
    @ViewBuilder
    private var gameModeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("memory.settings.gamemode".localized)
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(GameMode.allCases, id: \.rawValue) { mode in
                    gameModeCard(mode: mode)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.05), radius: 5)
        )
    }
    
    @ViewBuilder
    private func gameModeCard(mode: GameMode) -> some View {
        HStack(spacing: 16) {
            Image(systemName: mode == .singlePlayer ? "person.fill" : "person.2.fill")
                .font(.title2)
                .foregroundColor(viewModel.selectedGameMode == mode ? .white : .blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(mode.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(viewModel.selectedGameMode == mode ? .white : .primary)
                
                Text(mode == .singlePlayer ? "memory.mode.single.desc".localized : "memory.mode.two.desc".localized)
                    .font(.caption)
                    .foregroundColor(viewModel.selectedGameMode == mode ? .white.opacity(0.8) : .secondary)
            }
            
            Spacer()
            
            if viewModel.selectedGameMode == mode {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.white)
                    .font(.title3)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(viewModel.selectedGameMode == mode ? Color.blue : Color.clear)
        )
        .onTapGesture {
            withAnimation(.spring()) {
                viewModel.selectedGameMode = mode
            }
        }
    }
    
    // MARK: - Grid Size Section
    @ViewBuilder
    private var gridSizeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("memory.settings.gridsize".localized)
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(GridSize.allCases, id: \.rawValue) { size in
                    gridSizeCard(size: size)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.05), radius: 5)
        )
    }
    
    @ViewBuilder
    private func gridSizeCard(size: GridSize) -> some View {
        VStack(spacing: 12) {
            // Grid visualization
            gridVisualization(size: size)
            
            VStack(spacing: 4) {
                Text(size.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(viewModel.selectedGridSize == size ? .white : .primary)
                
                Text(size.difficulty)
                    .font(.caption2)
                    .foregroundColor(viewModel.selectedGridSize == size ? .white.opacity(0.8) : .secondary)
                
                Text("\(size.totalCards) " + LanguageManager.shared.getLocalizedString(for: "memory.cards"))
                    .font(.caption2)
                    .foregroundColor(viewModel.selectedGridSize == size ? .white.opacity(0.8) : .secondary)
            }
            
            if viewModel.selectedGridSize == size {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.white)
                    .font(.caption)
            }
        }
        .padding()
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(viewModel.selectedGridSize == size ? Color.green : Color.gray.opacity(0.1))
                .stroke(viewModel.selectedGridSize == size ? Color.green : Color.gray.opacity(0.3), lineWidth: 1)
        )
        .onTapGesture {
            withAnimation(.spring()) {
                viewModel.selectedGridSize = size
            }
        }
    }
    
    @ViewBuilder
    private func gridVisualization(size: GridSize) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: min(size.columns, 4))
        
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(0..<min(size.totalCards, 16), id: \.self) { _ in
                RoundedRectangle(cornerRadius: 2)
                    .fill(viewModel.selectedGridSize == size ? Color.white.opacity(0.8) : Color.gray.opacity(0.6))
                    .frame(width: 8, height: 8)
            }
        }
        .frame(width: 40, height: 30)
    }
    
    // MARK: - Current Game Info
    @ViewBuilder
    private var currentGameInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "gamecontroller.fill")
                    .foregroundColor(.orange)
                
                Text("memory.settings.current.game".localized)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("memory.settings.active.warning".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let stats = viewModel.currentStats {
                    HStack {
                        Text("memory.stats.time".localized + ": " + stats.formattedTime)
                        Spacer()
                        Text("memory.stats.moves".localized + ": \(stats.moves)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Best Score Section
    @ViewBuilder
    private var bestScoreSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                
                Text("memory.settings.best.score".localized)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            if let bestScore = viewModel.getBestScore() {
                Text("\(bestScore) " + "memory.settings.points".localized)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
            } else {
                Text("memory.settings.no.score".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.1))
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Helper Functions
    private func applySettings() {
        viewModel.applySettings()
        dismiss()
    }
}