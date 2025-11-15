//
//  MemoryCardView.swift
//  LifeCompanion
//
//  Created on 06.11.2025.
//

import SwiftUI

struct MemoryCardView: View {
    let card: MemoryCard
    let onTap: () -> Void
    @ObservedObject var viewModel: MemoryGameViewModel
    
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Card Background
            RoundedRectangle(cornerRadius: 12)
                .fill(viewModel.cardColor(for: card))
                .stroke(viewModel.cardBorderColor(for: card), lineWidth: 2)
            
            // Card Content
            ZStack {
                // Card Back (when not flipped)
                if !card.isFlipped && !card.isMatched {
                    VStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: cardIconSize))
                            .foregroundColor(.blue.opacity(0.7))
                        
                        Text("?")
                            .font(.system(size: cardIconSize, weight: .bold))
                            .foregroundColor(.blue.opacity(0.7))
                    }
                }
                
                // Card Front (when flipped or matched)
                if card.isFlipped || card.isMatched {
                    Text(card.symbol)
                        .font(.system(size: cardSymbolSize))
                        .scaleEffect(isAnimating ? 1.3 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAnimating)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .scaleEffect(card.isMatched ? 0.95 : 1.0)
        .opacity(card.isMatched ? 0.8 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: card.isFlipped)
        .animation(.easeInOut(duration: 0.3), value: card.isMatched)
        .onTapGesture {
            viewModel.flipCard(card)
        }
        .onChange(of: card.isMatched) { matched in
            if matched {
                // Celebration animation for matched cards
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    isAnimating = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isAnimating = false
                }
            }
        }
    }
    
    private var cardSymbolSize: CGFloat {
        switch viewModel.selectedGridSize {
        case .small: return 40
        case .medium: return 35
        case .large: return 30
        case .extraLarge: return 25
        case .huge: return 20
        }
    }
    
    private var cardIconSize: CGFloat {
        switch viewModel.selectedGridSize {
        case .small: return 20
        case .medium: return 18
        case .large: return 16
        case .extraLarge: return 14
        case .huge: return 12
        }
    }
}

// MARK: - Card Grid Component
struct MemoryCardGrid: View {
    let cards: [MemoryCard]
    let gridSize: GridSize
    @ObservedObject var viewModel: MemoryGameViewModel
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width - 32 // Account for padding
            let cardSize = calculateOptimalCardSize(for: availableWidth)
            let spacing: CGFloat = 8
            
            VStack(spacing: spacing) {
                ForEach(0..<actualRows, id: \.self) { row in
                    HStack(spacing: spacing) {
                        // Calculate cards in this row for smart centering
                        let startIndex = row * gridSize.columns
                        let endIndex = min(startIndex + gridSize.columns, cards.count)
                        let cardsInThisRow = endIndex - startIndex
                        let isLastRow = row == actualRows - 1
                        let isIncompleteRow = cardsInThisRow < gridSize.columns && isLastRow
                        
                        // Special handling for 3x3 grid with odd number of cards
                        let is3x3Grid = gridSize.columns == 3 && gridSize.rows == 3
                        let hasOddCards = cards.count % 2 == 1
                        let shouldCenterOddBottom = is3x3Grid && hasOddCards && isIncompleteRow && cardsInThisRow == 1
                        
                        // For incomplete last row, add leading spacer to center
                        if isIncompleteRow {
                            Spacer()
                            
                            // Extra centering for single card in 3x3 grid
                            if shouldCenterOddBottom {
                                Spacer()
                            }
                        }
                        
                        ForEach(startIndex..<endIndex, id: \.self) { cardIndex in
                            MemoryCardView(
                                card: cards[cardIndex],
                                onTap: { viewModel.flipCard(cards[cardIndex]) },
                                viewModel: viewModel
                            )
                            .frame(width: cardSize, height: cardSize)
                        }
                        
                        // Add invisible placeholders only for complete rows to maintain structure
                        if !isIncompleteRow {
                            ForEach(endIndex..<(row + 1) * gridSize.columns, id: \.self) { _ in
                                Color.clear
                                    .frame(width: cardSize, height: cardSize)
                            }
                        }
                        
                        // For incomplete last row, add trailing spacer to center
                        if isIncompleteRow {
                            // Extra centering for single card in 3x3 grid
                            if shouldCenterOddBottom {
                                Spacer()
                            }
                            
                            Spacer()
                        }
                    }
                }
            }
        }
        .aspectRatio(gridAspectRatio, contentMode: .fit)
        .padding()
    }
    
    // Calculate optimal card size based on available width
    private func calculateOptimalCardSize(for availableWidth: CGFloat) -> CGFloat {
        let spacing: CGFloat = 8
        let totalSpacing = spacing * CGFloat(gridSize.columns - 1)
        let cardWidth = (availableWidth - totalSpacing) / CGFloat(gridSize.columns)
        return max(cardWidth, 40) // Minimum size of 40 points
    }
    
    // Calculate actual number of rows needed
    private var actualRows: Int {
        return Int(ceil(Double(cards.count) / Double(gridSize.columns)))
    }
    
    // Calculate number of cards in a specific row
    private func cardsInRow(row: Int) -> Int {
        let startIndex = row * gridSize.columns
        let endIndex = min(startIndex + gridSize.columns, cards.count)
        return max(0, endIndex - startIndex)
    }
    
    // Calculate grid aspect ratio for proper layout
    private var gridAspectRatio: CGFloat {
        let spacing: CGFloat = 8
        
        let totalWidth = CGFloat(gridSize.columns) + (CGFloat(gridSize.columns - 1) * spacing / 80) // Approximate spacing ratio
        let totalHeight = CGFloat(gridSize.rows) + (CGFloat(gridSize.rows - 1) * spacing / 80) // Approximate spacing ratio
        
        return totalWidth / totalHeight
    }

}
