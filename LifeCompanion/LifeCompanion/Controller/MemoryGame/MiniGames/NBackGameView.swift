import SwiftUI

// Modern info card for N and Score
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
                .foregroundColor(.primary)
        }
        .frame(width: 80, height: 54)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: color.opacity(0.08), radius: 2, x: 0, y: 1)
    }
}


public struct NBackGameView: View {
    @Binding var showMainMenu: Bool
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var sequence: [String] = []
    @State private var defaultHintLetters: [String] = []
    @State private var userAnswers: [Bool] = []
    @State private var currentIndex: Int = 0
    @State private var n: Int = 2
    @State private var nSequence: [Int] = []
    @State private var score: Int = 0
    @State private var showResult: Bool = false
    @State private var finished: Bool = false
    @State private var showHint: Bool = false
    @State private var hintLetters: [String] = []
    let sequenceLength = 20
    let possibleN = [1, 2, 3]
    let possibleItems = ["A", "B", "C", "D", "E", "F", "G", "H"]

    public var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.purple.opacity(0.12), Color.blue.opacity(0.10), Color.orange.opacity(0.08), Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            VStack(spacing: 32) {
                Button(action: { showMainMenu = true }) {
                    Text("Ana Menüye Dön")
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(10)
                }
                HStack(spacing: 12) {
                    Image(systemName: "circle.grid.cross")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.purple)
                    Text(languageManager.getLocalizedString(for: "nback.title"))
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.purple)
                        .padding(.top, 16)
                }
                HStack(spacing: 18) {
                    InfoCard(title: "N", value: "N = \(n)", color: .purple)
                    InfoCard(title: languageManager.getLocalizedString(for: "nback.score"), value: "\(score)", color: .blue)
                }
                Spacer(minLength: 0)
                if !finished {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(LinearGradient(colors: [Color.blue.opacity(0.18), Color.purple.opacity(0.12)], startPoint: .top, endPoint: .bottom))
                            .shadow(color: .purple.opacity(0.12), radius: 10, x: 0, y: 6)
                        if !sequence.isEmpty && currentIndex < sequence.count {
                            Text(sequence[currentIndex])
                                .font(.system(size: 72, weight: .bold))
                                .foregroundColor(.white)
                                .padding()
                                .shadow(color: .blue.opacity(0.18), radius: 6, x: 0, y: 2)
                                .animation(.spring(), value: sequence[currentIndex])
                        } else {
                            Text("")
                        }
                    }
                    .frame(height: 120)
                    HStack(spacing: 18) {
                        SwiftUI.Button(action: {
                            answer(true)
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                Text(languageManager.getLocalizedString(for: "nback.match"))
                                    .font(.headline)
                            }
                            .frame(maxWidth: 110)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 8)
                            .background(LinearGradient(colors: [Color.green.opacity(0.85), Color.green.opacity(0.65)], startPoint: .top, endPoint: .bottom))
                            .foregroundColor(.white)
                            .cornerRadius(14)
                            .shadow(color: Color.green.opacity(0.18), radius: 3, x: 0, y: 1)
                        }
                        SwiftUI.Button(action: {
                            answer(false)
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                Text(languageManager.getLocalizedString(for: "nback.nomatch"))
                                    .font(.headline)
                            }
                            .frame(maxWidth: 110)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 8)
                            .background(LinearGradient(colors: [Color.red.opacity(0.85), Color.red.opacity(0.65)], startPoint: .top, endPoint: .bottom))
                            .foregroundColor(.white)
                            .cornerRadius(14)
                            .shadow(color: Color.red.opacity(0.18), radius: 3, x: 0, y: 1)
                        }
                    }
                    SwiftUI.Button(action: {
                        hintLetters = Array(sequence.prefix(currentIndex).suffix(5))
                        showHint = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            showHint = false
                        }
                    }) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .font(.title3)
                            Text(languageManager.getLocalizedString(for: "nback.hint"))
                                .font(.subheadline)
                        }
                        .frame(maxWidth: 110)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 8)
                        .background(LinearGradient(colors: [Color.orange.opacity(0.85), Color.orange.opacity(0.65)], startPoint: .top, endPoint: .bottom))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: Color.orange.opacity(0.18), radius: 2, x: 0, y: 1)
                    }
                    VStack(spacing: 4) {
                        if showHint && !hintLetters.isEmpty {
                            Text("Son 3 harf: ")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                            HStack(spacing: 8) {
                                ForEach(hintLetters, id: \ .self) { char in
                                    Text(char)
                                        .font(.headline)
                                        .frame(width: 32, height: 32)
                                        .background(LinearGradient(colors: [Color.orange.opacity(0.18), Color.yellow.opacity(0.12)], startPoint: .top, endPoint: .bottom))
                                        .cornerRadius(6)
                                        .shadow(color: .orange.opacity(0.12), radius: 1, x: 0, y: 1)
                                }
                            }
                        } else {
                            Color.clear
                                .frame(height: 38)
                        }
                    }
                    .padding(.top, 8)
                } else {
                    VStack(spacing: 24) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 22)
                                .fill(LinearGradient(colors: [Color.purple.opacity(0.18), Color.blue.opacity(0.12)], startPoint: .top, endPoint: .bottom))
                                .shadow(color: .purple.opacity(0.12), radius: 10, x: 0, y: 6)
                            VStack(spacing: 12) {
                                Text(languageManager.getLocalizedString(for: "nback.finished"))
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                                    .shadow(color: .purple.opacity(0.18), radius: 4, x: 0, y: 2)
                                Text("Skor: \(score) / \(sequenceLength-n)")
                                    .font(.title)
                                    .foregroundColor(.yellow)
                            }
                        }
                        .frame(height: 120)
                        SwiftUI.Button(action: {
                            restartGame()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                    .font(.title2)
                                Text(languageManager.getLocalizedString(for: "nback.restart"))
                                    .font(.title2)
                            }
                            .padding()
                            .background(LinearGradient(colors: [Color.purple.opacity(0.85), Color.purple.opacity(0.65)], startPoint: .top, endPoint: .bottom))
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(color: Color.purple.opacity(0.18), radius: 4, x: 0, y: 2)
                        }
                    }
                }
                Spacer()
                // Back button kaldırıldı
            }
            .padding()
        }
        .onAppear {
            startGame()
        }
    }

    func startGame() {
        // 3 random harf ekle, geçmişte varmış gibi
        defaultHintLetters = (0..<3).map { _ in possibleItems.randomElement()! }
        let mainSequence = (0..<sequenceLength).map { _ in possibleItems.randomElement()! }
        sequence = defaultHintLetters + mainSequence
        nSequence = (0..<sequence.count).map { _ in possibleN.randomElement()! }
        userAnswers = []
        currentIndex = 3 // ilk 3 harf geçmişte varmış gibi başla
        n = nSequence[currentIndex]
        score = 0
        finished = false
        // İlk açılışta hint göster
        hintLetters = defaultHintLetters
        showHint = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showHint = false
        }
    }
    
    func answer(_ isMatch: Bool) {
        guard currentIndex < sequence.count else { return }
        let currentN = nSequence[currentIndex]
        let match: Bool
        if currentIndex >= currentN {
            match = sequence[currentIndex] == sequence[currentIndex - currentN]
        } else {
            match = false
        }
        if isMatch == match {
            score += 1
        }
        userAnswers.append(isMatch)
        if currentIndex == sequence.count - 1 {
            finished = true
        } else {
            currentIndex += 1
            n = nSequence[currentIndex]
        }
    }
    
    func restartGame() {
        startGame()
    }
}
