//
//  ContentView.swift
//  LifeCompanion
//
//  Created by gayeugur on 25.10.2025.
//
import SwiftUI


// MARK: - Main View
struct ContentView: View {
    let menuItems = [
        MenuItem(title: NSLocalizedString("menu.todos", comment: "To-Do List"), icon: "checklist", color: .blue),
        MenuItem(title: NSLocalizedString("menu.habits", comment: "Habits"), icon: "chart.bar", color: .green),
        MenuItem(title: NSLocalizedString("menu.health", comment: "Health"), icon: "heart.fill", color: .red),
        MenuItem(title: NSLocalizedString("menu.meditation", comment: "Meditation"), icon: "leaf.fill", color: .purple),
        MenuItem(title: NSLocalizedString("menu.memoryGame", comment: "Memory Game"), icon: "gamecontroller.fill", color: .orange),
        MenuItem(title: NSLocalizedString("menu.settings", comment: "Settings"), icon: "gearshape.fill", color: .gray)
    ]
    
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
            .navigationTitle(NSLocalizedString("app.title", comment: "Life Companion"))
        }
    }
    
    @ViewBuilder
    private func destinationView(for item: MenuItem) -> some View {
        switch item.title {
        case NSLocalizedString("menu.todos", comment: ""):
            TodoListView()
        case NSLocalizedString("menu.habits", comment: ""):
            HabitsView()
        case NSLocalizedString("menu.health", comment: ""):
            HealthView()
        case NSLocalizedString("menu.meditation", comment: ""):
            MeditationView()
        case NSLocalizedString("menu.memoryGame", comment: ""):
            HabitsView()
        case NSLocalizedString("menu.settings", comment: ""): 
            HabitsView()
        default:
            Text(NSLocalizedString("menu.comingSoon", comment: "Coming Soon"))
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
