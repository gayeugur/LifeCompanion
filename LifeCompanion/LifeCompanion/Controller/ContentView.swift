//
//  ContentView.swift
//  LifeCompanion
//
//  Created by gayeugur on 25.10.2025.
//
import SwiftUI


// MARK: - Main View
struct ContentView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var feedbackManager: FeedbackManager
    @EnvironmentObject private var settingsManager: SettingsManager
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var refreshKey = UUID()
    
    var menuItems: [MenuItem] {
        [
            MenuItem(title: "menu.todos".localized, icon: "checklist", color: .blue),
            MenuItem(title: "menu.habits".localized, icon: "chart.bar", color: .green),
            MenuItem(title: "menu.health".localized, icon: "heart.fill", color: .red),
            MenuItem(title: "menu.meditation".localized, icon: "leaf.fill", color: .purple),
            MenuItem(title: "menu.memoryGame".localized, icon: "gamecontroller.fill", color: .orange),
            MenuItem(title: "menu.settings".localized, icon: "gearshape.fill", color: .gray)
        ]
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    let spacing: CGFloat = 20
                    let columns = [
                        GridItem(.adaptive(minimum: geometry.size.width / 2 - spacing * 1.5))
                    ]
                    
                    LazyVGrid(columns: columns, spacing: spacing) {
                        ForEach(menuItems) { item in
                            NavigationLink(destination: destinationView(for: item)) {
                                MenuItemView(item: item, size: geometry.size.width / 2 - spacing * 1.5)
                            }
                        }
                    }
                    .padding(spacing)
                }
            }
            .navigationTitle("app.title".localized)
            .id(refreshKey)
            .onReceive(NotificationCenter.default.publisher(for: .languageDidChange)) { _ in
                refreshKey = UUID()
            }
        }
    }
    
    @ViewBuilder
    private func destinationView(for item: MenuItem) -> some View {
        switch item.title {
        case "menu.todos".localized:
            TodoListView()
        case "menu.habits".localized:
            HabitsView()
        case "menu.health".localized:
            HealthView()
        case "menu.meditation".localized:
            MeditationView()
        case "menu.memoryGame".localized:
            WorkingMemoryGameView()
        case "menu.settings".localized: 
            SettingsView()
        default:
            Text("menu.comingSoon".localized)
        }
    }
}

// MARK: - Menu Item View
struct MenuItemView: View {
    let item: MenuItem
    let size: CGFloat
    
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: item.icon)
                .font(.system(size: size * 0.2))
                .foregroundColor(.white)
            
            Text(item.title)
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .frame(width: size, height: size)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(item.color)
                .shadow(color: item.color.opacity(0.3), radius: 10, x: 0, y: 5)
        )
    }
}
