//
//  HabitSuggestionsSheet.swift
//  LifeCompanion
//
//  Created by gayeugur on 3.11.2025.
//

import SwiftUI

struct HabitSuggestionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onTemplateSelected: (HabitTemplate) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Beautiful multi-layer gradient background
                ZStack {
                    // Base gradient
                    LinearGradient(
                        colors: [
                            Color.green.opacity(0.12),
                            Color.mint.opacity(0.08),
                            Color.teal.opacity(0.06),
                            Color.cyan.opacity(0.04),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Overlay gradient for depth
                    RadialGradient(
                        colors: [
                            Color.green.opacity(0.06),
                            Color.clear
                        ],
                        center: .topTrailing,
                        startRadius: 50,
                        endRadius: 400
                    )
                    
                    // Subtle pattern overlay
                    RadialGradient(
                        colors: [
                            Color.mint.opacity(0.03),
                            Color.clear
                        ],
                        center: .bottomLeading,
                        startRadius: 100,
                        endRadius: 300
                    )
                }
                .ignoresSafeArea()
                
                ScrollView {
                VStack(spacing: 20) {
                    // Başlık ve açıklama
                    VStack(spacing: 12) {
                        HStack(spacing: 16) {
                            // Enhanced icon with background
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.yellow.opacity(0.2), Color.orange.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 56, height: 56)
                                
                                Image(systemName: "sparkles")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.yellow, .orange],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .yellow.opacity(0.3), radius: 2)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("habit.suggestions.title".localized)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text("habit.suggestions.subtitle".localized)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            
                            Spacer()
                        }
                        
                        // Decorative divider
                        HStack {
                            Rectangle()
                                .fill(LinearGradient(
                                    colors: [Color.green.opacity(0.6), Color.green.opacity(0.2), Color.clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .frame(height: 2)
                            
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.green.opacity(0.6))
                            
                            Rectangle()
                                .fill(LinearGradient(
                                    colors: [Color.clear, Color.green.opacity(0.2), Color.green.opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .frame(height: 2)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    
                    // Kategorilere göre gruplandırılmış öneriler
                    ForEach(HabitCategory.allCases, id: \.self) { category in
                        let categoryTemplates = HabitTemplate.suggestions.filter { $0.category == category }
                        
                        if !categoryTemplates.isEmpty {
                            categorySection(category: category, templates: categoryTemplates)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
        }
            .navigationTitle("habit.suggestions.navigation.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func categorySection(category: HabitCategory, templates: [HabitTemplate]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Kategori başlığı
            HStack(spacing: 12) {
                // Enhanced category icon with background
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color(category.color).opacity(0.15), Color(category.color).opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: category.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(category.color))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.localizedName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("\(templates.count) önerileri")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Enhanced kategori badge'i
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                    
                    Text("\(templates.count)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(category.color), Color(category.color).opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: Color(category.color).opacity(0.3), radius: 2, x: 0, y: 1)
            }
            .padding(.horizontal, 20)
            
            // Kategori önerileri - horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(templates) { template in
                        suggestionCard(template: template)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    private func suggestionCard(template: HabitTemplate) -> some View {
        Button(action: {
            onTemplateSelected(template)
        }) {
            VStack(spacing: 8) {
                // Enhanced header with gradient icon and count
                HStack(spacing: 8) {
                    // Enhanced Icon with gradient background
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(template.category.color).opacity(0.2),
                                        Color(template.category.color).opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: template.icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(template.category.color))
                    }
                    
                    Spacer()
                    
                    // Enhanced count badge with gradient
                    HStack(spacing: 3) {
                        Text("\(template.targetCount)")
                            .font(.system(size: 11, weight: .bold))
                        Image(systemName: "target")
                            .font(.system(size: 8, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(template.category.color),
                                        Color(template.category.color).opacity(0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .shadow(color: Color(template.category.color).opacity(0.3), radius: 1, x: 0, y: 1)
                }
                
                // Başlık
                Text(template.title.localized)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Frequency
                HStack {
                    Text(template.frequency.displayName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.3)
                    
                    Spacer()
                    
                    // Category indicator
                    Circle()
                        .fill(Color(template.category.color).opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: 140, height: 75)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(template.category.color).opacity(0.25), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .onTapGesture {
            // Hafif haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }
}