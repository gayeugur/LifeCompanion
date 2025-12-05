import SwiftUI

struct GameCardButton: View {
    let icon: String
    let color: Color
    let titleKey: String
    let descriptionKey: String
    let action: () -> Void
    @EnvironmentObject private var languageManager: LanguageManager
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.18))
                        .frame(width: 56, height: 56)
                        .shadow(color: color.opacity(0.18), radius: 8, x: 0, y: 4)
                    Image(systemName: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 32)
                        .foregroundColor(color)
                }
                Text(languageManager.getLocalizedString(for: titleKey))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Text(languageManager.getLocalizedString(for: descriptionKey))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 150, height: 150)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(.systemBackground).opacity(0.98))
                    .shadow(color: color.opacity(0.18), radius: 8, x: 0, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(color.opacity(0.22), lineWidth: 2)
            )
            .scaleEffect(icon == "questionmark.circle" ? 0.95 : 1.0)
            .opacity(icon == "questionmark.circle" ? 0.7 : 1.0)
            .animation(.spring(), value: icon)
        }
    }
}
