import SwiftUI

struct MemoryGameMenuView: View {
    @Binding var showMainMenu: Bool
    @EnvironmentObject private var languageManager: LanguageManager
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.08), Color.purple.opacity(0.08), Color.orange.opacity(0.04), Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()

            VStack(spacing: 28) {
                Text(languageManager.getLocalizedString(for: "memory.menu.title"))
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
                            titleKey: languageManager.getLocalizedString(for: "memory.path.title"),
                            descriptionKey: languageManager.getLocalizedString(for: "memory.path.desc")
                        )
                    }
                    NavigationLink(destination: WorkingMemoryGameView(showMainMenu: $showMainMenu)) {
                        GameCardButton(
                            icon: "brain.head.profile",
                            color: .yellow,
                            titleKey: languageManager.getLocalizedString(for: "memory.working.title"),
                            descriptionKey: languageManager.getLocalizedString(for: "memory.working.desc")
                        )
                    }
                    NavigationLink(destination: NBackGameView(showMainMenu: $showMainMenu)) {
                        GameCardButton(
                            icon: "circle.grid.cross",
                            color: .purple,
                            titleKey: languageManager.getLocalizedString(for: "memory.nback.title"),
                            descriptionKey: languageManager.getLocalizedString(for: "memory.nback.desc")
                        )
                    }
                    NavigationLink(destination: TetroMemoryGameView(showMainMenu: $showMainMenu)) {
                        GameCardButton(
                            icon: "square.grid.3x3.fill",
                            color: .blue,
                            titleKey: languageManager.getLocalizedString(for: "memory.tetro.title"),
                            descriptionKey: languageManager.getLocalizedString(for: "memory.tetro.desc")
                        )
                    }
                }
                .padding(.horizontal, 12)
            }
        }
    }
}
