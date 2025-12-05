
import SwiftUI

struct MemoryGameMenuView: View {
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.08), Color.purple.opacity(0.08),
                             Color.orange.opacity(0.04), Color.white],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ).ignoresSafeArea()

                VStack(spacing: 28) {
                    Text("Memory Games")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.blue)
                        .padding(.top, 36)

                    LazyVGrid(columns: [
                        GridItem(.flexible()), GridItem(.flexible())
                    ], spacing: 28) {
                        
                        GameCardButton(
                            icon: "map",
                            color: .green,
                            titleKey: "Path Memory",
                            descriptionKey: "Follow the path!",
                            action: {
                                navigationPath.append("PathMemory")
                            }
                        )

                        GameCardButton(
                            icon: "brain.head.profile",
                            color: .yellow,
                            titleKey: "Working Memory",
                            descriptionKey: "Train your memory",
                            action: {
                                navigationPath.append("WorkingMemory")
                            }
                        )

                        GameCardButton(
                            icon: "circle.grid.cross",
                            color: .purple,
                            titleKey: "N-back",
                            descriptionKey: "Cognitive challenge",
                            action: {
                                navigationPath.append("NBackGame")
                            }
                        )

                        GameCardButton(
                            icon: "square.grid.3x3.fill",
                            color: .blue,
                            titleKey: "Tetro Memory",
                            descriptionKey: "Tetris-style memory",
                            action: {
                                navigationPath.append("TetroMemory")
                            }
                        )

                       
                    }
                    .padding(.horizontal, 12)
                }
            }
            .navigationDestination(for: String.self) { value in
                switch value {
                case "PathMemory":
                    PathMemoryGameView()

                case "WorkingMemory":
                    WorkingMemoryGameView()

                case "NBackGame":
                    NBackGameView()

                case "TetroMemory":
                    TetroMemoryGameView()

                default:
                    EmptyView()
                }
            }
        }
    }
}
