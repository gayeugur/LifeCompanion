struct PathMemoryGameView_Previews: PreviewProvider {
    static var previews: some View {
        PathMemoryGameView(showMainMenu: .constant(false))
    }
}
import SwiftUI

public struct PathMemoryGameView: View {
    @Binding var showMainMenu: Bool
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
                    InfoCard(title: languageManager.getLocalizedString(for: "pathmemory.level"),
                             value: "Level \(round)", color: .green)
                    InfoCard(title: languageManager.getLocalizedString(for: "pathmemory.step"),
                             value: "\(userPath.count) / \(path.count)", color: .orange)
                    InfoCard(title: languageManager.getLocalizedString(for: "pathmemory.attempts"),
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
            HStack(spacing: 10) {
                Image(systemName: "arrow.clockwise")
                    .font(.title2)
                Text(languageManager.getLocalizedString(for: "pathmemory.restart"))
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .padding(.horizontal, 8)
            .background(
                LinearGradient(
                    colors: [Color.green.opacity(0.95), Color.green.opacity(0.7), Color.green.opacity(0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(18)
            .shadow(color: Color.green.opacity(0.22), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
        }
    }

    // backButton kaldırıldı

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
        // 3 adım ile başla, her 5 levelde bir adım sayısını 1 artır
        let pathLength = 3 + (round / 5)
        path = (0..<pathLength).map { _ in Int.random(in: 0..<(gridSize * gridSize)) }
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
            // Otomatik devam: kısa bir gecikmeden sonra yeni round başlat
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                startRound()
            }
        } else {
            remainingAttempts -= 1
            if remainingAttempts > 0 {
                result = "Yanlış! Kalan hak: \(remainingAttempts)"
            } else {
                result = "Wrong!"
                gameOver = true
                showFailAlert = true
                // Hatalı durumda path ve userPath temizlensin
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    userPath = []
                    path = []
                }
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

