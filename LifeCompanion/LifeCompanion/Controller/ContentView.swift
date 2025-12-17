//
//  ContentView.swift
//  LifeCompanion
//
//  Created by gayeugur on 25.10.2025.
//
import SwiftUI


// MARK: - Main View
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var feedbackManager: FeedbackManager
    @EnvironmentObject private var settingsManager: SettingsManager
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var refreshKey = UUID()
    @State private var navigationPath = NavigationPath()
    @StateObject private var appNavState = AppNavigationState()
    @StateObject private var habitViewModel = HabitListViewModel()
    
    // Performance optimization: Cache menu items to avoid repeated localization calls
    private var menuItems: [MenuItem] {
        [
            MenuItem(title: "menu.todos".localized, icon: "checklist", color: .blue, route: .todos),
            MenuItem(title: "menu.habits".localized, icon: "chart.bar", color: .green, route: .habits),
            MenuItem(title: "menu.health".localized, icon: "heart.fill", color: .red, route: .health),
            MenuItem(title: "menu.meditation".localized, icon: "leaf.fill", color: .purple, route: .meditation),
            MenuItem(title: "menu.memoryGame".localized, icon: "gamecontroller.fill", color: .orange, route: .memoryGame),
            MenuItem(title: "menu.settings".localized, icon: "gearshape.fill", color: .gray, route: .settings)
        ]
    }
    
    @State private var showMainMenu = true

    var body: some View {
        NavigationStack(path: $navigationPath) {
            if showMainMenu {
                GeometryReader { geometry in
                    ScrollView {
                        let spacing: CGFloat = 20
                        let columns = [
                            GridItem(.adaptive(minimum: geometry.size.width / 2 - spacing * 1.5))
                        ]
                        LazyVGrid(columns: columns, spacing: spacing) {
                            ForEach(menuItems, id: \ .title) { item in
                                Button(action: {
                                    navigationPath.append(item.route)
                                }) {
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
                .onChange(of: scenePhase) { _, newPhase in
                    switch newPhase {
                    case .active:
                        habitViewModel.configure(settingsManager: settingsManager)
                        habitViewModel.fetchHabits(from: modelContext)
                        habitViewModel.checkAutoReset(in: modelContext, settingsManager: settingsManager)
                    case .background:
                        break
                    case .inactive:
                        break
                    @unknown default:
                        break
                    }
                }
                .onAppear {
                    habitViewModel.configure(settingsManager: settingsManager)
                    habitViewModel.fetchHabits(from: modelContext)
                    habitViewModel.checkAutoReset(in: modelContext, settingsManager: settingsManager)
                }
                .navigationDestination(for: AppRoute.self) { route in
                    destinationView(for: route)
                }
            } else {
                TetroMemoryGameView(showMainMenu: $showMainMenu)
            }
        }
        .environmentObject(appNavState) // 🔥 BURASI KRİTİK
                .onChange(of: appNavState.showMainMenu) { _, newValue in
                    if newValue {
                        navigationPath = NavigationPath() // 🔥 POP TO ROOT
                    }
                }
    }
    
    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .todos:
            TodoListView()
        case .habits:
            HabitsView()
        case .health:
            HealthView()
        case .meditation:
            MeditationView()
        case .memoryGame:
            MemoryGameMenuView(showMainMenu: $showMainMenu)
        case .settings:
            SettingsView()
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
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.15), value: item.id)
    }
}
