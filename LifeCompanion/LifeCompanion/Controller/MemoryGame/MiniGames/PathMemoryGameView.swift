import SwiftUI

public struct PathMemoryGameView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var languageManager: LanguageManager

    @State private var path: [Int] = []
    @State private var userPath: [Int] = []
    @State private var showPath = false
    @State private var result: String = ""
    @State private var round = 1
    @State private var gameOver = false
    @State private var currentShowIndex: Int? = nil
    @State private var remainingAttempts: Int = 3
    @State private var showFailAlert: Bool = false

    let gridSize = 4

    public var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.08),
                    Color.purple.opacity(0.08),
                    Color.orange.opacity(0.04),
                    Color.white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                // TITLE
                Text(languageManager.getLocalizedString(for: "pathmemory.title"))
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.blue)
                    .padding(.top, 16)

                // INFO CARDS
                HStack(spacing: 18) {
                    InfoCard(title: "Level",
                             value: "Level \(round)", color: .green)
                    InfoCard(title: "Step",
                             value: "\(userPath.count) / \(path.count)", color: .orange)
                    InfoCard(title: "Attempts",
                             value: "\(remainingAttempts)", color: .red)
                }

                // GRID
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(.systemGray6).opacity(0.95))
                        .shadow(color: .blue.opacity(0.08), radius: 8, x: 0, y: 4)
                        .frame(height: 260)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: gridSize),
                              spacing: 12) {
                        ForEach(0..<(gridSize * gridSize), id: \.self) { i in
                            Button(action: {
                                handleTileTap(i)
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(userPath.contains(i)
                                              ? Color.green.opacity(0.7)
                                              : Color.white)
                                        .frame(height: 48)
                                        .shadow(color: .gray.opacity(0.18),
                                                radius: 4, x: 0, y: 2)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(Color.blue.opacity(0.18), lineWidth: 2)
                                        )
                                        .animation(.easeInOut(duration: 0.2),
                                                   value: userPath)

                                    // Sequence indicator
                                    if showPath,
                                       let index = path.firstIndex(of: i),
                                       let current = currentShowIndex,
                                       index <= current {
                                        Circle()
                                            .fill(index == current ? Color.orange : Color.blue)
                                            .frame(width: 18, height: 18)
                                            .shadow(color: .orange.opacity(0.18),
                                                    radius: 4, x: 0, y: 2)
                                    }

                                    // Tap checkmark
                                    if userPath.contains(i) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white)
                                            .font(.title3)
                                            .transition(.scale)
                                    }
                                }
                            }
                            .disabled(showPath || gameOver)
                        }
                    }
                }

                // Step indicators
                HStack(spacing: 8) {
                    ForEach(0..<path.count, id: \.self) { idx in
                        Circle()
                            .fill(idx < userPath.count ? Color.green : Color.gray.opacity(0.3))
                            .frame(width: 18, height: 18)
                            .overlay(
                                Text("\(idx + 1)")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            )
                    }
                }

                // RESULT TEXT
                resultSection

                // BUTTONS
                HStack(spacing: 16) {
                    restartButton
                    backButton
                }

                Spacer()
            }
            .padding()
        }
        .onAppear { startRound() }
        .alert(isPresented: $showFailAlert) {
            Alert(
                title: Text(languageManager.getLocalizedString(for: "pathmemory.failed")),
                message: Text(languageManager.getLocalizedString(for: "pathmemory.failedMessage")),
                dismissButton: .default(
                    Text(languageManager.getLocalizedString(for: "pathmemory.close"))
                ) {
                    // Reset only alert state
                    showFailAlert = false
                }
            )
        }
    }
}

// MARK: - COMPONENTS
private extension PathMemoryGameView {

    var restartButton: some View {
        Button(action: restartGame) {
            Text(languageManager.getLocalizedString(for: "pathmemory.restart"))
                .font(.title3)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Color(.systemGreen).opacity(0.85))
                .foregroundColor(.white)
                .cornerRadius(16)
                .shadow(color: Color(.systemGreen).opacity(0.18), radius: 4, x: 0, y: 2)
        }
    }

    var backButton: some View {
        Button(action: { dismiss() }) {
            HStack {
                Image(systemName: "arrow.left.circle.fill").font(.title2)
                Text(languageManager.getLocalizedString(for: "memory.game.back"))
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(16)
            .shadow(color: Color.blue.opacity(0.25), radius: 6, x: 0, y: 3)
        }
    }

    var resultSection: some View {
        Group {
            if result == "Correct!" {
                Text(languageManager.getLocalizedString(for: "pathmemory.correct"))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            } else if result == "Wrong!" {
                Text(languageManager.getLocalizedString(for: "pathmemory.wrong"))
                    .foregroundColor(.red)
                    .font(.title3)
                    .fontWeight(.semibold)
            } else if result.contains("Yanlış!") {
                Text(
                    String(
                        format: languageManager.getLocalizedString(for: "pathmemory.wrongAttempts"),
                        remainingAttempts
                    )
                )
                .foregroundColor(.red)
                .font(.title3)
                .fontWeight(.semibold)
            } else {
                Text("").opacity(0)
            }
        }
        .frame(minHeight: 38)
    }
}

// MARK: - GAME LOGIC
private extension PathMemoryGameView {

    func handleTileTap(_ i: Int) {
        if showPath || gameOver || path.isEmpty { return }

        let nextIndex = userPath.count

        if path.indices.contains(nextIndex) {
            if i == path[nextIndex] {
                userPath.append(i)
                if userPath.count == path.count {
                    checkAnswer()
                }
            } else {
                remainingAttempts -= 1

                if remainingAttempts > 0 {
                    result = "Yanlış! Kalan hak: \(remainingAttempts)"
                } else {
                    result = "Wrong!"
                    gameOver = true
                    showFailAlert = true
                }
            }
        }
    }

    func startRound() {
        userPath = []
        result = ""
        path = (0..<(round + 2)).map { _ in Int.random(in: 0..<(gridSize * gridSize)) }
        showPath = true
        currentShowIndex = 0
        showNextPathStep()
    }

    func showNextPathStep() {
        guard let idx = currentShowIndex, idx < path.count else {
            showPath = false
            currentShowIndex = nil
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            currentShowIndex = idx + 1
            showNextPathStep()
        }
    }

    func checkAnswer() {
        if userPath == path {
            result = "Correct!"
            round += 1
            remainingAttempts = 3
        } else {
            remainingAttempts -= 1

            if remainingAttempts > 0 {
                result = "Yanlış! Kalan hak: \(remainingAttempts)"
            } else {
                result = "Wrong!"
                gameOver = true
                showFailAlert = true
            }
        }
    }

    func restartGame() {
        round = 1
        gameOver = false
        remainingAttempts = 3
        userPath = []
        result = ""

        path = (0..<(round + 2)).map { _ in Int.random(in: 0..<(gridSize * gridSize)) }

        showPath = true
        currentShowIndex = 0

        showNextPathStep()
    }
}

// MARK: - INFO CARD
fileprivate struct InfoCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(color)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(width: 80, height: 54)
        .background(RoundedRectangle(cornerRadius: 12).fill(color.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(color.opacity(0.18), lineWidth: 1))
        .shadow(color: color.opacity(0.08), radius: 2, x: 0, y: 1)
    }
}

