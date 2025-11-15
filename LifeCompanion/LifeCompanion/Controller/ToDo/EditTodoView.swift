//
//  EditTodoView.swift
//  LifeCompanion
//
//  Created by gayeugur on 10.11.2025.
//

import SwiftUI
import SwiftData
import UserNotifications

struct EditTodoView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settingsManager: SettingsManager

    let todo: TodoItem
    
    @State private var title: String = ""
    @State private var subtitle: String = ""
    @State private var priority: TodoItem.Priority = .medium
    @State private var dueDate: Date = Date().addingTimeInterval(60 * 60)
    @State private var enableReminder: Bool = false
    @State private var showValidationAlert: Bool = false

    // FOCUS STATE — yalnızca title & subtitle için kullanıyoruz
    @FocusState private var isFieldFocused: Bool

    private var isSaveDisabled: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Theme-adaptive blue gradient background
                LinearGradient(
                    colors: [
                        Color.primaryBackground,
                        Color.blue.opacity(0.06),
                        Color.secondaryBackground.opacity(0.4),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                    VStack(spacing: 24) {
                        // Başlık + Alt başlık
                        card {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("edit.section.details".localized)
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                    
                                    Spacer()
                                }

                                TextField("edit.title.placeholder".localized, text: $title)
                                    .focused($isFieldFocused)
                                    .padding(14)
                                    .background(Color.tertiaryBackground, in: RoundedRectangle(cornerRadius: 16))

                                TextField("edit.subtitle.placeholder".localized, text: $subtitle)
                                    .focused($isFieldFocused)
                                    .padding(14)
                                    .background(Color.tertiaryBackground, in: RoundedRectangle(cornerRadius: 16))
                            }
                        }

                        // Öncelik
                        card {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("edit.priority".localized)
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                Picker("", selection: $priority) {
                                    Text("priority.low".localized).tag(TodoItem.Priority.low)
                                    Text("priority.medium".localized).tag(TodoItem.Priority.medium)
                                    Text("priority.high".localized).tag(TodoItem.Priority.high)
                                }
                                .pickerStyle(.segmented)
                            }
                        }

                        // Hatırlatma
                        card {
                            VStack(alignment: .leading, spacing: 10) {
                                Toggle("edit.reminder".localized, isOn: $enableReminder)
                                if enableReminder {
                                    DatePicker("edit.datetime".localized,
                                               selection: $dueDate,
                                               displayedComponents: [.date, .hourAndMinute])
                                        .datePickerStyle(.compact)
                                }
                            }
                        }
                    }
                    .padding(20)
                }
                .onTapGesture {
                    // boşluğa tıklayınca yalnızca text field'lardan focus kaldırıyoruz (klavye kapanır)
                    isFieldFocused = false
                }

                // Kaydet butonu (mavi gradyan)
                Button {
                    updateTodo()
                } label: {
                    Text("edit.save".localized)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(colors: [Color.blue.opacity(0.85), Color.blue],
                                           startPoint: .top,
                                           endPoint: .bottom)
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                        .shadow(color: isSaveDisabled ? .clear : Color.blue.opacity(0.35), radius: 16, y: 8)
                }
                .disabled(isSaveDisabled)
                .opacity(isSaveDisabled ? 0.4 : 1)
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
            .navigationTitle("edit.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Klavye üstü Done butonu
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("common.done".localized) { isFieldFocused = false }
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                    }
                }
            }
            .alert(LocalizedStringKey("edit.validation.title".localized), isPresented: $showValidationAlert) {
                Button("edit.ok".localized, role: .cancel) {}
            } message: {
                Text("edit.validation.message".localized)
            }
        }
        .onAppear {
            setupInitialValues()
        }
    }

    // Kart helper (AddTodoView ile aynı stil)
    @ViewBuilder
    private func card<Content: View>(@ViewBuilder _ c: () -> Content) -> some View {
        c()
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.cardBackground)
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.blue.opacity(0.03))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.borderColor.opacity(0.1), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }

    private func setupInitialValues() {
        title = todo.title
        subtitle = todo.notes ?? ""
        priority = todo.priority
        enableReminder = todo.dueDate != nil
        if let dueDate = todo.dueDate {
            self.dueDate = dueDate
        }
    }

    private func updateTodo() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            showValidationAlert = true
            return
        }

        print("🔄 Updating Todo:")
        print("   Original: '\(todo.title)' -> New: '\(trimmed)'")
        print("   Notes: '\(todo.notes ?? "nil")' -> '\(subtitle)'")
        print("   Priority: \(todo.priority) -> \(priority)")
        print("   Due Date: \(String(describing: todo.dueDate)) -> \(enableReminder ? String(describing: dueDate) : "nil")")

        // Cancel old notification first
        cancelNotification(for: todo)

        // Update todo properties
        todo.title = trimmed
        todo.notes = subtitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : subtitle
        todo.priority = priority
        todo.dueDate = enableReminder ? dueDate : nil

        print("✏️ Updated todo object:")
        print("   Title: '\(todo.title)'")
        print("   Notes: '\(todo.notes ?? "nil")'")
        print("   Priority: \(todo.priority)")
        print("   Due Date: \(String(describing: todo.dueDate))")

        do {
            try modelContext.save()
            print("✅ ModelContext saved successfully!")
            
            // Schedule new notification if needed
            if enableReminder, let _ = todo.dueDate, !todo.isCompleted {
                scheduleNotification(for: todo)
            }
            
            dismiss()
        } catch {
            print("❌ Failed to save modelContext: \(error)")
        }
    }

    private func cancelNotification(for todo: TodoItem) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [todo.id.uuidString])
    }

    private func scheduleNotification(for todo: TodoItem) {
        // Don't schedule notification if notifications are disabled
        guard settingsManager.notificationsEnabled else {
            return
        }
        
        // Don't schedule notification for completed todos
        guard !todo.isCompleted else {
            return
        }
        
        guard let date = todo.dueDate else {
            return
        }
        
        // Don't schedule notification for past dates
        guard date > Date() else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "📝 " + todo.title
        content.body = "todo.notification.body".localized
        if let subtitle = todo.notes, !subtitle.isEmpty { 
            content.body = subtitle 
        }
        content.sound = .default
        content.categoryIdentifier = "TODO_REMINDER"

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: todo.id.uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                // Handle error silently
            }
        }
    }
}