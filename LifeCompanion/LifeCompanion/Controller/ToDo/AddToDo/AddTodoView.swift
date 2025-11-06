//
//  AddTodoView.swift
//  LifeCompanion
//
//  Created by gayeugur on 25.10.2025.
//

import SwiftUI
import SwiftData
import UserNotifications

struct AddTodoView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var subtitle: String = ""
    @State private var priority: TodoItem.Priority = .medium
    @State private var dueDate: Date = Date().addingTimeInterval(60 * 60)
    @State private var enableReminder: Bool = false
    @State private var showValidationAlert: Bool = false
    @State private var showingSuggestionsSheet: Bool = false

    // FOCUS STATE — yalnızca title & subtitle için kullanıyoruz (A seçimi)
    @FocusState private var isFieldFocused: Bool

    private var isSaveDisabled: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Başlık + Alt başlık
                        card {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("add.section.details".localized)
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                    
                                    Spacer()
                                    
                                    // Öneriler butonu
                                    Button(action: {
                                        showingSuggestionsSheet = true
                                    }) {
                                        HStack(spacing: 5) {
                                            Image(systemName: "lightbulb.fill")
                                                .font(.system(size: 12))
                                            Text("todo.suggestions.button".localized)
                                                .font(.system(size: 12, weight: .semibold))
                                        }
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(.ultraThinMaterial)
                                                .overlay(
                                                    Capsule()
                                                        .stroke(Color.blue.opacity(0.4), lineWidth: 1)
                                                )
                                        )
                                        .shadow(color: Color.blue.opacity(0.2), radius: 2, x: 0, y: 1)
                                    }
                                }

                                TextField("add.title.placeholder".localized, text: $title)
                                    .focused($isFieldFocused) // <— odak bağlandı
                                    .padding(14)
                                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                                TextField("add.subtitle.placeholder".localized, text: $subtitle)
                                    .focused($isFieldFocused) // <— aynı focus state ile bağlandı
                                    .padding(14)
                                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                            }
                        }

                        // Öncelik
                        card {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("add.priority".localized)
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
                                Toggle("add.reminder".localized, isOn: $enableReminder)
                                if enableReminder {
                                    DatePicker("add.datetime".localized,
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
                    saveTodo()
                } label: {
                    Text("add.save".localized)
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
            .background(
                LinearGradient(colors: [Color.blue.opacity(0.08), Color.blue.opacity(0.02)],
                               startPoint: .top,
                               endPoint: .bottom)
                    .ignoresSafeArea()
            )
            .navigationTitle("add.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Klavye üstü Done butonu
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { isFieldFocused = false }
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                    }
                }
            }
            .alert(LocalizedStringKey("add.validation.title"), isPresented: $showValidationAlert) {
                Button("add.ok", role: .cancel) {}
            } message: {
                Text("add.validation.message")
            }
            .sheet(isPresented: $showingSuggestionsSheet) {
                TodoSuggestionsSheet { template in
                    applyTemplate(template)
                    showingSuggestionsSheet = false
                }
            }
        }
    }

    // Kart helper (Habits/AddHabitView tarzı, mavi tonlu)
    @ViewBuilder
    private func card<Content: View>(@ViewBuilder _ c: () -> Content) -> some View {
        c()
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.blue.opacity(0.05))
                }
            )
            .shadow(color: .black.opacity(0.05), radius: 14, y: 4)
    }

    private func applyTemplate(_ template: TodoTemplate) {
        withAnimation(.easeInOut) {
            title = template.title.localized
            subtitle = template.subtitle?.localized ?? ""
            
            // Priority mapping
            switch template.priority {
            case .low:
                priority = .low
            case .medium:
                priority = .medium
            case .high:
                priority = .high
            }
            
            enableReminder = template.hasReminder
            if template.hasReminder {
                // Set due date to 1 hour from now
                dueDate = Date().addingTimeInterval(60 * 60)
            }
        }
        // Klavye odağını kaldır
        isFieldFocused = false
    }

    private func saveTodo() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            showValidationAlert = true
            return
        }

        let todo = TodoItem(
            title: trimmed,
            isCompleted: false,
            dueDate: enableReminder ? dueDate : nil,
            priority: priority,
            notes: subtitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : subtitle
        )

        modelContext.insert(todo)
        do {
            try modelContext.save()
            if enableReminder, let _ = todo.dueDate {
                scheduleNotification(for: todo)
            }
            dismiss()
        } catch {
            print("Todo kaydedilirken hata: \(error)")
        }
    }

    private func scheduleNotification(for todo: TodoItem) {
        let content = UNMutableNotificationContent()
        content.title = todo.title
        if let subtitle = todo.notes { content.subtitle = subtitle }
        content.sound = .default

        guard let date = todo.dueDate else { return }
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: todo.id.uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification schedule error: \(error)")
            }
        }
    }
}
