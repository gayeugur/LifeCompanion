
import SwiftUI

struct MemoryGameMenuView: View {
    @Binding var showMainMenu: Bool
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.08), Color.purple.opacity(0.08), Color.orange.opacity(0.04), Color.white],
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
                    NavigationLink(destination: PathMemoryGameView(showMainMenu: $showMainMenu)) {
                        GameCardButton(
                            icon: "map",
                            color: .green,
                            titleKey: "Path Memory",
                            descriptionKey: "Follow the path!"
                        )
                    }
                    NavigationLink(destination: WorkingMemoryGameView(showMainMenu: $showMainMenu)) {
                        GameCardButton(
                            icon: "brain.head.profile",
                            color: .yellow,
                            titleKey: "Working Memory",
                            descriptionKey: "Train your memory"
                        )
                    }
                    NavigationLink(destination: NBackGameView(showMainMenu: $showMainMenu)) {
                        GameCardButton(
                            icon: "circle.grid.cross",
                            color: .purple,
                            titleKey: "N-back",
                            descriptionKey: "Cognitive challenge"
                        )
                    }
                    NavigationLink(destination: TetroMemoryGameView(showMainMenu: $showMainMenu)) {
                        GameCardButton(
                            icon: "square.grid.3x3.fill",
                            color: .blue,
                            titleKey: "Tetro Memory",
                            descriptionKey: "Tetris-style memory"
                        )
                    }
                }
                .padding(.horizontal, 12)
            }
        }
    }
}
