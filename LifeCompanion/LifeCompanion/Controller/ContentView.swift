//
//  ContentView.swift
//  LifeCompanion
//
//  Created by gayeugur on 25.10.2025.
//
import SwiftUI
import SwiftData


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
    @Query private var allTodos: [TodoItem]
    @Query private var allHabits: [HabitItem]
    @Query private var allWaterIntakes: [WaterIntake]
    
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

    private var dailySummary: DailySummary {
        let calendar = Calendar.current
        let today = Date()

        let completedTodosToday = allTodos.filter {
            $0.isCompleted && calendar.isDate($0.taskDate, inSameDayAs: today)
        }.count

        let completedHabitsToday = allHabits.reduce(0) { result, habit in
            result + habit.entries.filter { entry in
                entry.isCompleted && calendar.isDate(entry.date, inSameDayAs: today)
            }.count
        }

        let todayWater = allWaterIntakes.first(where: { calendar.isDate($0.date, inSameDayAs: today) })
        let waterAmount = todayWater?.amount ?? 0
        let waterGoal = todayWater?.dailyGoal ?? settingsManager.dailyWaterGoal

        let meditationToday = UserDefaults.standard.integer(forKey: "meditation_today_\(todayDateKey())")
        let bestHabitStreak = allHabits.map(\.longestStreak).max() ?? 0

        return DailySummary(
            completedTodosToday: completedTodosToday,
            completedHabitsToday: completedHabitsToday,
            todayWaterAmount: waterAmount,
            todayWaterGoal: waterGoal,
            todayMeditationMinutes: meditationToday,
            bestHabitStreak: bestHabitStreak
        )
    }

    private var earnedBadges: [AchievementBadge] {
        var badges: [AchievementBadge] = []
        let summary = dailySummary

        if summary.completedTodosToday >= 3 {
            badges.append(AchievementBadge(id: "todo3", title: "badge.todo3.title".localized, icon: "checkmark.seal.fill", color: .blue))
        }
        if summary.completedHabitsToday >= 3 {
            badges.append(AchievementBadge(id: "habit3", title: "badge.habit3.title".localized, icon: "leaf.fill", color: .green))
        }
        if summary.todayWaterAmount >= summary.todayWaterGoal {
            badges.append(AchievementBadge(id: "water", title: "badge.water.title".localized, icon: "drop.fill", color: .cyan))
        }
        if summary.bestHabitStreak >= 7 {
            badges.append(AchievementBadge(id: "streak7", title: "badge.streak7.title".localized, icon: "flame.fill", color: .orange))
        }
        if summary.todayMeditationMinutes >= 10 {
            badges.append(AchievementBadge(id: "meditation10", title: "badge.meditation10.title".localized, icon: "brain.head.profile", color: .purple))
        }

        return badges
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            if showMainMenu {
                GeometryReader { geometry in
                    ScrollView {
                        VStack(spacing: 16) {
                            dailySummaryCard
                            achievementsCard

                        let spacing: CGFloat = 20
                        let columns = [
                            GridItem(.adaptive(minimum: geometry.size.width / 2 - spacing * 1.5))
                        ]
                        LazyVGrid(columns: columns, spacing: spacing) {
                            ForEach(menuItems, id: \.title) { item in
                                Button(action: {
                                    navigationPath.append(item.route)
                                }) {
                                    MenuItemView(item: item, size: geometry.size.width / 2 - spacing * 1.5)
                                }
                            }
                        }
                        }
                        .padding(20)
                    }
                    .background(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.12),
                                Color.cyan.opacity(0.06),
                                Color.indigo.opacity(0.04),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
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
    private var dailySummaryCard: some View {
        let summary = dailySummary

        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("home.summary.title".localized, systemImage: "calendar.badge.clock")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                Text(todayDateLabel)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.35))
                    )
            }

            HStack(spacing: 8) {
                summaryPill(
                    icon: "checklist.checked",
                    text: "home.summary.todos.completed".localized + ": \(summary.completedTodosToday)",
                    color: .blue
                )
                summaryPill(
                    icon: "chart.bar.fill",
                    text: "home.summary.habits.completed".localized + ": \(summary.completedHabitsToday)",
                    color: .green
                )
            }

            HStack(spacing: 8) {
                summaryPill(
                    icon: "drop.fill",
                    text: "home.summary.water".localized + ": \(summary.todayWaterAmount)/\(summary.todayWaterGoal) ml",
                    color: .cyan
                )
                summaryPill(
                    icon: "brain.head.profile",
                    text: "home.summary.meditation".localized + ": \(summary.todayMeditationMinutes) " + "meditation.minutes".localized,
                    color: .purple
                )
            }
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var achievementsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("home.badges.title".localized, systemImage: "rosette")
                .font(.system(size: 16, weight: .semibold))

            if earnedBadges.isEmpty {
                Text("home.badges.empty".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(earnedBadges) { badge in
                            HStack(spacing: 6) {
                                Image(systemName: badge.icon)
                                    .foregroundColor(badge.color)
                                    .font(.system(size: 13, weight: .semibold))
                                Text(badge.title)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [badge.color.opacity(0.24), badge.color.opacity(0.12)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        Capsule(style: .continuous)
                                            .stroke(badge.color.opacity(0.35), lineWidth: 1)
                                    )
                            )
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func summaryPill(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 9) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.22))
                    .frame(width: 24, height: 24)

                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 11, weight: .semibold))
            }

            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.19), color.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(color.opacity(0.22), lineWidth: 1)
                )
        )
    }

    private var todayDateLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: Date())
    }

    private func todayDateKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
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

private struct DailySummary {
    let completedTodosToday: Int
    let completedHabitsToday: Int
    let todayWaterAmount: Int
    let todayWaterGoal: Int
    let todayMeditationMinutes: Int
    let bestHabitStreak: Int
}

private struct AchievementBadge: Identifiable {
    let id: String
    let title: String
    let icon: String
    let color: Color
}

// MARK: - Menu Item View
struct MenuItemView: View {
    let item: MenuItem
    let size: CGFloat
    
    var body: some View {
        VStack(spacing: 11) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [item.color.opacity(0.95), item.color.opacity(0.78), item.color.opacity(0.55)],
                            center: .topLeading,
                            startRadius: 8,
                            endRadius: size * 0.45
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.45), lineWidth: 1)
                    )

                Circle()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: size * 0.26, height: size * 0.26)
                    .offset(x: size * 0.13, y: -size * 0.14)

                Image(systemName: item.icon)
                    .font(.system(size: size * 0.22, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(width: size * 0.78, height: size * 0.78)
            .shadow(color: item.color.opacity(0.34), radius: 12, x: 0, y: 8)

            Text(item.title)
                .font(.system(size: max(14, size * 0.095), weight: .semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: size * 0.88)
        }
        .frame(width: size, height: size * 0.98)
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.15), value: item.id)
    }
}
