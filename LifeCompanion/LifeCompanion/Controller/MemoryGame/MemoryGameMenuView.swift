import SwiftUI

struct MemoryGameMenuView: View {
    @Binding var showMainMenu: Bool
    @EnvironmentObject private var languageManager: LanguageManager

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        ZStack {
            Color(red: 0.97, green: 0.98, blue: 0.99)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerCard

                    LazyVGrid(columns: columns, spacing: 14) {
                        NavigationLink(destination: PathMemoryGameView(showMainMenu: $showMainMenu)) {
                            GameCardButton(
                                icon: "map",
                                color: .green,
                                title: languageManager.getLocalizedString(for: "memory.path.title"),
                                description: languageManager.getLocalizedString(for: "memory.path.desc")
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink(destination: WorkingMemoryGameView(showMainMenu: $showMainMenu)) {
                            GameCardButton(
                                icon: "brain.head.profile",
                                color: .orange,
                                title: languageManager.getLocalizedString(for: "memory.working.title"),
                                description: languageManager.getLocalizedString(for: "memory.working.desc")
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink(destination: NBackGameView(showMainMenu: $showMainMenu)) {
                            GameCardButton(
                                icon: "circle.grid.cross",
                                color: .purple,
                                title: languageManager.getLocalizedString(for: "memory.nback.title"),
                                description: languageManager.getLocalizedString(for: "memory.nback.desc")
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink(destination: TetroMemoryGameView(showMainMenu: $showMainMenu)) {
                            GameCardButton(
                                icon: "square.grid.3x3.fill",
                                color: .blue,
                                title: languageManager.getLocalizedString(for: "memory.tetro.title"),
                                description: languageManager.getLocalizedString(for: "memory.tetro.desc")
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 24)
            }
        }
    }

    private var headerCard: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 56, height: 56)
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 27, weight: .bold))
                    .foregroundColor(.orange)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(languageManager.getLocalizedString(for: "memory.menu.title"))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(2)

                Text("4 Games")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.orange.opacity(0.08), radius: 12, x: 0, y: 8)
    }
}
