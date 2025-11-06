//
//  ConfirmationDialog.swift
//  LifeCompanion
//
//  Created by gayeugur on 3.11.2025.
//

import SwiftUI

struct ConfirmationDialog: View {
    let title: String
    let message: String
    let confirmButtonTitle: String
    let cancelButtonTitle: String
    let confirmAction: () -> Void
    let cancelAction: () -> Void
    let isDestructive: Bool
    
    @Environment(\.dismiss) private var dismiss
    
    init(
        title: String,
        message: String,
        confirmButtonTitle: String = "confirm.yes",
        cancelButtonTitle: String = "confirm.cancel",
        isDestructive: Bool = false,
        confirmAction: @escaping () -> Void,
        cancelAction: @escaping () -> Void = {}
    ) {
        self.title = title
        self.message = message
        self.confirmButtonTitle = confirmButtonTitle
        self.cancelButtonTitle = cancelButtonTitle
        self.confirmAction = confirmAction
        self.cancelAction = cancelAction
        self.isDestructive = isDestructive
    }
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    handleCancel()
                }
            
            // Dialog content
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    // Icon
                    Image(systemName: isDestructive ? "trash.fill" : "questionmark.circle.fill")
                        .font(.system(size: 50, weight: .light))
                        .foregroundColor(isDestructive ? .red : .blue)
                        .symbolEffect(.pulse, options: .repeating)
                    
                    // Title
                    Text(title.localized)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    // Message
                    Text(message.localized)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
                .padding(.top, 8)
                
                // Buttons
                VStack(spacing: 12) {
                    // Confirm button
                    Button(action: {
                        confirmAction()
                        dismiss()
                    }) {
                        Text(confirmButtonTitle.localized)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: isDestructive 
                                        ? [Color.red.opacity(0.9), Color.red]
                                        : [Color.blue.opacity(0.9), Color.blue],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(12)
                    }
                    
                    // Cancel button
                    Button(action: handleCancel) {
                        Text(cancelButtonTitle.localized)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 40)
            .transition(.scale.combined(with: .opacity))
        }
    }
    
    private func handleCancel() {
        cancelAction()
        dismiss()
    }
}

// MARK: - View Modifier
struct ConfirmationDialogModifier: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    let confirmButtonTitle: String
    let cancelButtonTitle: String
    let isDestructive: Bool
    let confirmAction: () -> Void
    let cancelAction: () -> Void
    
    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isPresented) {
                ConfirmationDialog(
                    title: title,
                    message: message,
                    confirmButtonTitle: confirmButtonTitle,
                    cancelButtonTitle: cancelButtonTitle,
                    isDestructive: isDestructive,
                    confirmAction: confirmAction,
                    cancelAction: cancelAction
                )
                .background(ClearBackgroundView())
            }
    }
}

// MARK: - Clear Background View
struct ClearBackgroundView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - View Extension
extension View {
    func confirmationDialog(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        confirmButtonTitle: String = "confirm.yes",
        cancelButtonTitle: String = "confirm.cancel",
        isDestructive: Bool = false,
        confirmAction: @escaping () -> Void,
        cancelAction: @escaping () -> Void = {}
    ) -> some View {
        modifier(
            ConfirmationDialogModifier(
                isPresented: isPresented,
                title: title,
                message: message,
                confirmButtonTitle: confirmButtonTitle,
                cancelButtonTitle: cancelButtonTitle,
                isDestructive: isDestructive,
                confirmAction: confirmAction,
                cancelAction: cancelAction
            )
        )
    }
}