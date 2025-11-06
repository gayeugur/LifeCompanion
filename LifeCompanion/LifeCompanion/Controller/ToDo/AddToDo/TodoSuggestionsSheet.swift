//
//  TodoSuggestionsSheet.swift
//  LifeCompanion
//
//  Created by gayeugur on 3.11.2025.
//

import SwiftUI

struct TodoSuggestionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onTemplateSelected: (TodoTemplate) -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Başlık ve açıklama
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("todo.suggestions.title".localized)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text("todo.suggestions.subtitle".localized)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // Kategorilere göre gruplandırılmış öneriler
                    ForEach(TodoCategory.allCases, id: \.self) { category in
                        let categoryTemplates = TodoTemplate.suggestions.filter { $0.category == category }
                        
                        if !categoryTemplates.isEmpty {
                            categorySection(category: category, templates: categoryTemplates)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("todo.suggestions.navigation.title".localized)
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
    private func categorySection(category: TodoCategory, templates: [TodoTemplate]) -> some View {
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
    private func suggestionCard(template: TodoTemplate) -> some View {
        Button(action: {
            onTemplateSelected(template)
        }) {
            VStack(spacing: 8) {
                // Compact header with icon and priority
                HStack(spacing: 8) {
                    // Icon
                    Image(systemName: template.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(template.category.color))
                        .frame(width: 24, height: 24)
                    
                    Spacer()
                    
                    // Priority badge
                    HStack(spacing: 3) {
                        Circle()
                            .fill(template.priority.color)
                            .frame(width: 6, height: 6)
                        Text(template.priority.localizedName)
                            .font(.system(size: 10, weight: .medium))
                            .textCase(.uppercase)
                    }
                    .foregroundColor(template.priority.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(template.priority.color.opacity(0.15))
                    )
                }
                
                // Başlık
                Text(template.title.localized)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Subtitle (if exists)
                if let subtitle = template.subtitle {
                    Text(subtitle.localized)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Footer with reminder indicator
                HStack {
                    if template.hasReminder {
                        HStack(spacing: 3) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 8))
                            Text("todo.reminder".localized)
                                .font(.system(size: 9, weight: .medium))
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    // Category indicator
                    Circle()
                        .fill(Color(template.category.color).opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: 160, height: template.subtitle != nil ? 90 : 75)
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