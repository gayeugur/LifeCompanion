//
//  MemoryGameView.swift
//  LifeCompanion
//
//  Created on 06.11.2025.
//

import SwiftUI

struct MemoryGameView: View {
    @StateObject private var viewModel = MemoryGameViewModel()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var refreshKey = UUID()
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                    VStack(spacing: 20) {
                        // Game Header
                        gameHeader
                        
                        if let game = viewModel.game {
                            // Game Stats
                            gameStatsCard(game: game)
                            
                            // Game Board - Centered and responsive container
                            HStack {
                                Spacer(minLength: 10)
                                VStack {
                                    Spacer(minLength: 5)
                                    MemoryCardGrid(
                                        cards: game.cards,
                                        gridSize: game.gridSize,
                                        viewModel: viewModel
                                    )
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(.regularMaterial)
                                            .shadow(color: .black.opacity(0.1), radius: 10)
                                    )
                                    Spacer(minLength: 5)
                                }
                                Spacer(minLength: 10)
                            }
                            
                            // Game Controls - Centered
                            HStack {
                                Spacer()
                                gameControls
                                Spacer()
                            }
                            
                            // Bottom padding for better spacing
                            Spacer()
                                .frame(height: 20)
                            
                        } else {
                            // No Game State
                            newGamePrompt
                        }
                    }
                    .padding()
                }
        }
        .navigationTitle("memory.game.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.showingSettings = true
                }) {
                    Image(systemName: "gear")
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $viewModel.showingSettings) {
            GameSettingsView(viewModel: viewModel)
        }
        .id(refreshKey)
        .onReceive(NotificationCenter.default.publisher(for: .languageDidChange)) { _ in
            refreshKey = UUID()
        }
        .alert("memory.game.complete.title".localized, isPresented: $viewModel.showingGameComplete) {
            Button("memory.game.new".localized) {
                viewModel.startNewGame()
            }
            Button("memory.game.settings".localized) {
                viewModel.showingSettings = true
            }
            Button("common.cancel".localized, role: .cancel) { }
        } message: {
            if let stats = viewModel.currentStats {
                Text(gameCompleteMessage(stats: stats))
            }
        }
        .onAppear {
            if viewModel.game == nil {
                viewModel.startNewGame()
            }
        }
    }
    
    // MARK: - Game Header
    @ViewBuilder
    private var gameHeader: some View {
        VStack(spacing: 8) {
            Text("memory.game.title".localized)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            if let game = viewModel.game {
                HStack {
                    Text(game.gridSize.displayName)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(12)
                    
                    Text(game.gameMode.displayName)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Game Stats Card
    @ViewBuilder
    private func gameStatsCard(game: MemoryGame) -> some View {
        VStack(spacing: 16) {
            // Timer and Moves
            HStack(spacing: 20) {
                VStack {
                    Image(systemName: "clock")
                        .font(.title2)
                        .foregroundColor(.blue)
                    Text("memory.stats.time".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(game.gameStats.formattedTime)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Divider()
                    .frame(height: 40)
                
                VStack {
                    Image(systemName: "hand.point.up")
                        .font(.title2)
                        .foregroundColor(.orange)
                    Text("memory.stats.moves".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(game.moves)")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                if game.gameMode == .singlePlayer {
                    Divider()
                        .frame(height: 40)
                    
                    VStack {
                        Image(systemName: "target")
                            .font(.title2)
                            .foregroundColor(.green)
                        Text("memory.stats.accuracy".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(game.gameStats.formattedAccuracy)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }
            }
            
            // Two Player Scores
            if game.gameMode == .twoPlayer {
                Divider()
                
                HStack {
                    Spacer()
                    HStack(spacing: 30) {
                    VStack {
                        Text("memory.player.one".localized)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(game.currentPlayer == .playerOne ? .blue : .secondary)
                        
                        Text("\(game.playerOneScore)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(game.currentPlayer == .playerOne ? .blue : .primary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(game.currentPlayer == .playerOne ? Color.blue.opacity(0.1) : Color.clear)
                            .stroke(game.currentPlayer == .playerOne ? Color.blue : Color.clear, lineWidth: 2)
                    )
                    
                    VStack {
                        Text("memory.player.two".localized)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(game.currentPlayer == .playerTwo ? .red : .secondary)
                        
                        Text("\(game.playerTwoScore)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(game.currentPlayer == .playerTwo ? .red : .primary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(game.currentPlayer == .playerTwo ? Color.red.opacity(0.1) : Color.clear)
                            .stroke(game.currentPlayer == .playerTwo ? Color.red : Color.clear, lineWidth: 2)
                    )
                    }
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.1), radius: 5)
        )
    }
    
    // MARK: - Game Controls
    @ViewBuilder
    private var gameControls: some View {
        HStack(spacing: 16) {
            if let game = viewModel.game {
                switch game.gameState {
                case .playing:
                    Button(action: {
                        viewModel.pauseGame()
                    }) {
                        Label("memory.game.pause".localized, systemImage: "pause.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    
                case .paused:
                    Button(action: {
                        viewModel.resumeGame()
                    }) {
                        Label("memory.game.resume".localized, systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    
                case .finished:
                    Button(action: {
                        viewModel.startNewGame()
                    }) {
                        Label("memory.game.new".localized, systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)
                    
                case .notStarted:
                    Button(action: {
                        viewModel.startNewGame()
                    }) {
                        Label("memory.game.start".localized, systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            Button(action: {
                viewModel.resetGame()
            }) {
                Label("memory.game.reset".localized, systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.bordered)
        }
    }
    
    // MARK: - New Game Prompt
    @ViewBuilder
    private var newGamePrompt: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.7))
            
            Text("memory.game.welcome".localized)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text("memory.game.description".localized)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                Button(action: {
                    viewModel.startNewGame()
                }) {
                    Label("memory.game.start".localized, systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: {
                    viewModel.showingSettings = true
                }) {
                    Label("memory.game.settings".localized, systemImage: "gear")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10)
        )
    }
    
    // MARK: - Helper Functions
    private func gameCompleteMessage(stats: GameStats) -> String {
        if viewModel.selectedGameMode == .twoPlayer {
            if let winner = viewModel.game?.winner {
                return String(format: "memory.game.winner".localized, winner.displayName)
            } else {
                return "memory.game.tie".localized
            }
        } else {
            return String(format: "memory.game.complete.message".localized, 
                         stats.formattedTime, stats.moves, stats.formattedAccuracy)
        }
    }
}