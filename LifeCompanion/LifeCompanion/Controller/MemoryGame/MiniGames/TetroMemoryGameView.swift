import SwiftUI

struct TetroMemoryGameView: View {
    @Binding var showMainMenu: Bool
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var grid: [[Int]] = Array(repeating: Array(repeating: 0, count: 10), count: 20)
    @State private var currentPiece: Tetromino = Tetromino.random()
    @State private var piecePosition: (x: Int, y: Int) = (4, 0)
    @State private var isGameOver: Bool = false
    @State private var score: Int = 0
    @State private var timer: Timer? = nil

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.12), Color.purple.opacity(0.10), Color.white.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()
            VStack(spacing: 16) {
                Text(languageManager.getLocalizedString(for: "tetro.title"))
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.blue)
                Text(languageManager.getLocalizedString(for: "tetro.score"))
                    .font(.title2)
                Text("\(score)")
                    .font(.title2)
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 200, height: 400)
                    VStack(spacing: 1) {
                        ForEach(0..<20, id: \ .self) { row in
                            HStack(spacing: 1) {
                                ForEach(0..<10, id: \ .self) { col in
                                    Rectangle()
                                        .fill(colorForCell(row: row, col: col))
                                        .frame(width: 18, height: 18)
                                }
                            }
                        }
                    }
                }
                HStack(spacing: 24) {
                    Button("◀️") { movePiece(dx: -1) }
                        .font(.system(size: 36))
                        .frame(width: 60, height: 60)
                    Button("🔄") { rotatePiece() }
                        .font(.system(size: 36))
                        .frame(width: 60, height: 60)
                    Button("▶️") { movePiece(dx: 1) }
                        .font(.system(size: 36))
                        .frame(width: 60, height: 60)
                    Button("⬇️") { dropPiece() }
                        .font(.system(size: 36))
                        .frame(width: 60, height: 60)
                }
                .font(.title)
                if isGameOver {
                    Text(languageManager.getLocalizedString(for: "tetro.gameover"))
                        .font(.title)
                        .foregroundColor(.red)
                }
                Button(action: { restartGame() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                        Text("Restart")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: 220, minHeight: 44)
                    .background(
                        LinearGradient(
                            colors: [Color.green.opacity(0.85), Color.green.opacity(0.65)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .shadow(color: Color.green.opacity(0.13), radius: 4, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                    )
                    .padding(.top, 8)
                    .scaleEffect(isGameOver ? 1.05 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isGameOver)
                }
                Spacer()
                // Back button kaldırıldı
            }
            .padding(.top, 16)
            
        
        }
        .onAppear { startTimer() }
        .onDisappear { timer?.invalidate() }
    }

    func colorForCell(row: Int, col: Int) -> Color {
        if isPieceCell(row: row, col: col) {
            return currentPiece.color
        }
        switch grid[row][col] {
        case 1: return .blue
        case 2: return .green
        case 3: return .orange
        case 4: return .purple
        case 5: return .red
        case 6: return .yellow
        case 7: return .pink
        default: return .white
        }
    }

    func isPieceCell(row: Int, col: Int) -> Bool {
        for (py, line) in currentPiece.shape.enumerated() {
            for (px, cell) in line.enumerated() {
                if cell == 1 {
                    let gx = piecePosition.x + px
                    let gy = piecePosition.y + py
                    if gx == col && gy == row {
                        return true
                    }
                }
            }
        }
        return false
    }

    func movePiece(dx: Int) {
        let newX = piecePosition.x + dx
        if canMove(to: (newX, piecePosition.y)) {
            piecePosition.x = newX
        }
    }

    func rotatePiece() {
        let rotated = currentPiece.rotated()
        if canPlace(piece: rotated, at: piecePosition) {
            currentPiece = rotated
        }
    }

    func dropPiece() {
        while canMove(to: (piecePosition.x, piecePosition.y + 1)) {
            piecePosition.y += 1
        }
        placePiece()
    }

    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: true) { _ in
            if !isGameOver {
                if canMove(to: (piecePosition.x, piecePosition.y + 1)) {
                    piecePosition.y += 1
                } else {
                    placePiece()
                }
            }
        }
    }

    func canMove(to pos: (x: Int, y: Int)) -> Bool {
        return canPlace(piece: currentPiece, at: pos)
    }

    func canPlace(piece: Tetromino, at pos: (x: Int, y: Int)) -> Bool {
        for (py, line) in piece.shape.enumerated() {
            for (px, cell) in line.enumerated() {
                if cell == 1 {
                    let gx = pos.x + px
                    let gy = pos.y + py
                    if gx < 0 || gx >= 10 || gy < 0 || gy >= 20 { return false }
                    if grid[gy][gx] != 0 { return false }
                }
            }
        }
        return true
    }

    func placePiece() {
        for (py, line) in currentPiece.shape.enumerated() {
            for (px, cell) in line.enumerated() {
                if cell == 1 {
                    let gx = piecePosition.x + px
                    let gy = piecePosition.y + py
                    if gy >= 0 && gy < 20 && gx >= 0 && gx < 10 {
                        grid[gy][gx] = currentPiece.type
                    }
                }
            }
        }
        clearLines()
        score += 10
        spawnNewPiece()
    }

    func clearLines() {
        grid = grid.filter { row in row.contains(0) }
        let cleared = 20 - grid.count
        if cleared > 0 {
            for _ in 0..<cleared {
                grid.insert(Array(repeating: 0, count: 10), at: 0)
            }
            score += cleared * 100
        }
    }

    func spawnNewPiece() {
        currentPiece = Tetromino.random()
        piecePosition = (4, 0)
        if !canPlace(piece: currentPiece, at: piecePosition) {
            isGameOver = true
            timer?.invalidate()
        }
    }

    func restartGame() {
        grid = Array(repeating: Array(repeating: 0, count: 10), count: 20)
        score = 0
        isGameOver = false
        spawnNewPiece()
        startTimer()
    }
}

struct Tetromino {
    let shape: [[Int]]
    let type: Int
    let color: Color

    static func random() -> Tetromino {
        let all: [Tetromino] = [
            Tetromino(shape: [[1,1,1,1]], type: 1, color: .blue), // I
            Tetromino(shape: [[1,1],[1,1]], type: 2, color: .green), // O
            Tetromino(shape: [[0,1,0],[1,1,1]], type: 3, color: .orange), // T
            Tetromino(shape: [[1,0,0],[1,1,1]], type: 4, color: .purple), // J
            Tetromino(shape: [[0,0,1],[1,1,1]], type: 5, color: .red), // L
            Tetromino(shape: [[1,1,0],[0,1,1]], type: 6, color: .yellow), // S
            Tetromino(shape: [[0,1,1],[1,1,0]], type: 7, color: .pink) // Z
        ]
        return all.randomElement()!
    }

    func rotated() -> Tetromino {
        let newShape = rotateMatrix(shape)
        return Tetromino(shape: newShape, type: type, color: color)
    }

    private func rotateMatrix(_ matrix: [[Int]]) -> [[Int]] {
        let rowCount = matrix.count
        let colCount = matrix[0].count
        var result = Array(repeating: Array(repeating: 0, count: rowCount), count: colCount)
        for i in 0..<rowCount {
            for j in 0..<colCount {
                result[j][rowCount - i - 1] = matrix[i][j]
            }
        }
        return result
    }
}
