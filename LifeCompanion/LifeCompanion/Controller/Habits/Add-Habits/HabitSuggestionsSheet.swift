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
                // Green gradient background matching Habits theme
                LinearGradient(
                    colors: [
                        Color.green.opacity(0.08),
                        Color.green.opacity(0.04),
                        Color.mint.opacity(0.02),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                VStack(spacing: 20) {
                    // Başlık ve açıklama
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.yellow)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("habit.suggestions.title".localized)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text("habit.suggestions.subtitle".localized)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
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
            HStack {
                Image(systemName: category.icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color(category.color))
                
                Text(category.localizedName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Kategori badge'i
                Text("\(templates.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(category.color))
                    )
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
                // Compact header with icon and count
                HStack(spacing: 8) {
                    // Icon
                    Image(systemName: template.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(template.category.color))
                        .frame(width: 24, height: 24)
                    
                    Spacer()
                    
                    // Count badge
                    HStack(spacing: 3) {
                        Text("\(template.targetCount)")
                            .font(.system(size: 11, weight: .bold))
                        Image(systemName: "target")
                            .font(.system(size: 8))
                    }
                    .foregroundColor(Color(template.category.color))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color(template.category.color).opacity(0.15))
                    )
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