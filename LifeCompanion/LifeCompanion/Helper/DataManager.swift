//
//  DataManager.swift
//  LifeCompanion
//
//  Created on 7.11.2025.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import Foundation
import UIKit

class DataManager: ObservableObject {
    
    // MARK: - Data Export
    func exportUserData(context: ModelContext, format: ExportFormat = .json) -> URL? {
        print("🚀 ExportUserData called with format: \(format)")
        print("📱 ModelContext provided: \(context)")
        
        do {
            print("🔄 Starting export with format: \(format)")
            let exportData = try gatherAllUserData(context: context)
            print("📊 Gathered data - Habits: \(exportData.habits.count), Todos: \(exportData.todos.count), Medications: \(exportData.medications.count), Water: \(exportData.waterIntakes.count), Games: \(exportData.gameScores.count)")
            
            let tempURL: URL
            
            switch format {
            case .json:
                print("📄 Creating JSON export...")
                tempURL = try createJSONExport(exportData: exportData)
            case .pdf:
                print("📄 Creating Text Report export...")
                tempURL = try createPDFExport(exportData: exportData)
            }
            
            print("✅ Export successful, file created at: \(tempURL)")
            print("🔍 Absolute path: \(tempURL.absoluteString)")
            
            // Verify file exists
            if !FileManager.default.fileExists(atPath: tempURL.path) {
                print("❌ File does not exist at path: \(tempURL.path)")
                return nil
            }
            
            // Check file size
            if let attributes = try? FileManager.default.attributesOfItem(atPath: tempURL.path),
               let fileSize = attributes[.size] as? Int64 {
                print("📄 File size: \(fileSize) bytes")
                if fileSize == 0 {
                    print("❌ File is empty!")
                    return nil
                }
            } else {
                print("⚠️ Could not get file attributes")
            }
            
            return tempURL
        } catch {
            print("❌ Export failed with error: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            if let decodingError = error as? DecodingError {
                print("❌ Decoding error: \(decodingError)")
            }
            return nil
        }
    }
    
    private func createJSONExport(exportData: ExportData) throws -> URL {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let jsonData = try encoder.encode(exportData)
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("LifeCompanion_Export_\(dateString).json")
        
        print("📝 Writing JSON to: \(tempURL.path)")
        try jsonData.write(to: tempURL)
        
        // Verify file was written
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📄 JSON preview (first 200 chars): \(String(jsonString.prefix(200)))")
        }
        
        return tempURL
    }
    
    private func createPDFExport(exportData: ExportData) throws -> URL {
        // Create a comprehensive text report
        var reportContent = """
        LifeCompanion Data Export Report
        ================================
        
        Export Date: \(DateFormatter.localizedString(from: exportData.exportDate, dateStyle: .full, timeStyle: .medium))
        App Version: \(exportData.appVersion)
        
        """
        
        // Habits Section
        if !exportData.habits.isEmpty {
            reportContent += """
            
            HABITS (\(exportData.habits.count) items)
            ==========================================
            
            """
            
            for habit in exportData.habits {
                let status = habit.isCompleted ? "✓ Completed" : "○ In Progress"
                reportContent += """
                • \(habit.title)
                  Progress: \(habit.currentCount)/\(habit.targetCount)
                  Current Streak: \(habit.currentStreak) days
                  Longest Streak: \(habit.longestStreak) days
                  Status: \(status)
                  Frequency: \(habit.frequency)
                """
                if let notes = habit.notes, !notes.isEmpty {
                    reportContent += "\n  Notes: \(notes)"
                }
                reportContent += "\n  Created: \(DateFormatter.localizedString(from: habit.createdAt, dateStyle: .medium, timeStyle: .short))\n\n"
            }
        }
        
        // Todos Section
        if !exportData.todos.isEmpty {
            reportContent += """
            
            TODO ITEMS (\(exportData.todos.count) items)
            ============================================
            
            """
            
            for todo in exportData.todos {
                let status = todo.isCompleted ? "✓ Completed" : "○ Pending"
                reportContent += """
                • \(todo.title)
                  Priority: \(todo.priority)
                  Status: \(status)
                """
                if let notes = todo.notes, !notes.isEmpty {
                    reportContent += "\n  Notes: \(notes)"
                }
                if let dueDate = todo.dueDate {
                    reportContent += "\n  Due: \(DateFormatter.localizedString(from: dueDate, dateStyle: .medium, timeStyle: .short))"
                }
                reportContent += "\n  Created: \(DateFormatter.localizedString(from: todo.createdAt, dateStyle: .medium, timeStyle: .short))\n\n"
            }
        }
        
        // Medications Section
        if !exportData.medications.isEmpty {
            reportContent += """
            
            MEDICATIONS (\(exportData.medications.count) items)
            ===================================================
            
            """
            
            for medication in exportData.medications {
                let status = medication.isActive ? "✓ Active" : "⏸ Inactive"
                reportContent += """
                • \(medication.medicationName)
                  Dosage: \(medication.dosage)
                  Frequency: \(medication.frequency)
                  Status: \(status)
                  Added: \(DateFormatter.localizedString(from: medication.createdAt, dateStyle: .medium, timeStyle: .short))
                
                """
            }
        }
        
        // Water Intake Section
        if !exportData.waterIntakes.isEmpty {
            reportContent += """
            
            WATER INTAKE RECORDS (\(exportData.waterIntakes.count) entries)
            ============================================================
            
            """
            
            for water in exportData.waterIntakes {
                reportContent += """
                • \(DateFormatter.localizedString(from: water.date, dateStyle: .medium, timeStyle: .none))
                  Amount: \(water.amount)ml
                  Daily Goal: \(water.dailyGoal)ml
                  Progress: \(Int(Double(water.amount) / Double(water.dailyGoal) * 100))%
                
                """
            }
        }
        
        // Game Scores Section
        if !exportData.gameScores.isEmpty {
            reportContent += """
            
            MEMORY GAME SCORES (\(exportData.gameScores.count) games)
            ========================================================
            
            """
            
            for score in exportData.gameScores {
                let timeMinutes = score.timeInSeconds / 60
                let timeSeconds = score.timeInSeconds % 60
                let timeString = String(format: "%d:%02d", timeMinutes, timeSeconds)
                
                reportContent += """
                • \(DateFormatter.localizedString(from: score.date, dateStyle: .medium, timeStyle: .short))
                  Grid: \(score.gridSize)x\(score.gridSize)
                  Moves: \(score.moves)
                  Time: \(timeString)
                  Score: \(score.score)
                
                """
            }
        }
        
        reportContent += """
        
        ================================
        End of Report
        Generated by LifeCompanion App
        """
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("LifeCompanion_Export_\(dateString).txt")
        
        print("📝 Writing text report to: \(tempURL.path)")
        print("📄 Report preview (first 300 chars): \(String(reportContent.prefix(300)))")
        
        try reportContent.write(to: tempURL, atomically: true, encoding: .utf8)
        
        return tempURL
    }

    
    private func drawTodoItem(_ todo: ExportTodo, at y: CGFloat, leftMargin: CGFloat, rightMargin: CGFloat) -> CGFloat {
        let regularFont = UIFont.systemFont(ofSize: 11)
        let boldFont = UIFont.boldSystemFont(ofSize: 11)
        
        var currentY = y
        
        // Title
        let titleAttributes = [NSAttributedString.Key.font: boldFont]
        let statusIcon = todo.isCompleted ? "✓" : "○"
        "\(statusIcon) \(todo.title)".draw(at: CGPoint(x: leftMargin + 10, y: currentY), withAttributes: titleAttributes)
        currentY += 15
        
        // Details
        let detailAttributes = [NSAttributedString.Key.font: regularFont]
        let priority = "Priority: \(todo.priority)"
        priority.draw(at: CGPoint(x: leftMargin + 20, y: currentY), withAttributes: detailAttributes)
        currentY += 12
        
        if let notes = todo.notes, !notes.isEmpty {
            "Notes: \(notes)".draw(at: CGPoint(x: leftMargin + 20, y: currentY), withAttributes: detailAttributes)
            currentY += 12
        }
        
        return currentY + 8
    }
    

    
    private func gatherAllUserData(context: ModelContext) throws -> ExportData {
        print("🔄 Starting to gather user data...")
        
        // Gather all data from different models
        do {
            let habits = try context.fetch(FetchDescriptor<HabitItem>())
            print("✅ Fetched \(habits.count) habits")
            
            let todos = try context.fetch(FetchDescriptor<TodoItem>())
            print("✅ Fetched \(todos.count) todos")
            
            let medications = try context.fetch(FetchDescriptor<MedicationEntry>())
            print("✅ Fetched \(medications.count) medications")
            
            let waterIntakes = try context.fetch(FetchDescriptor<WaterIntake>())
            print("✅ Fetched \(waterIntakes.count) water intakes")
            
            let gameScores = try context.fetch(FetchDescriptor<GameScore>())
            print("✅ Fetched \(gameScores.count) game scores")
            
            print("📊 Raw data counts - Habits: \(habits.count), Todos: \(todos.count), Medications: \(medications.count), Water: \(waterIntakes.count), Games: \(gameScores.count)")
            
            print("🔄 Converting to export format...")
            let exportData = ExportData(
                exportDate: Date(),
                appVersion: "1.0.0",
                habits: habits.compactMap { 
                    do {
                        return ExportHabit(from: $0)
                    } catch {
                        print("❌ Error converting habit '\($0.title)': \(error)")
                        return nil
                    }
                },
                todos: todos.compactMap { 
                    do {
                        return ExportTodo(from: $0)
                    } catch {
                        print("❌ Error converting todo '\($0.title)': \(error)")
                        return nil
                    }
                },
                medications: medications.compactMap { 
                    do {
                        return ExportMedication(from: $0)
                    } catch {
                        print("❌ Error converting medication '\($0.medicationName)': \(error)")
                        return nil
                    }
                },
                waterIntakes: waterIntakes.compactMap { 
                    do {
                        return ExportWaterIntake(from: $0)
                    } catch {
                        print("❌ Error converting water intake: \(error)")
                        return nil
                    }
                },
                gameScores: gameScores.compactMap { 
                    do {
                        return ExportGameScore(from: $0)
                    } catch {
                        print("❌ Error converting game score: \(error)")
                        return nil
                    }
                }
            )
            print("✅ Export data created successfully")
            
            // If no data exists, add some sample data indication
            if exportData.habits.isEmpty && exportData.todos.isEmpty && 
               exportData.medications.isEmpty && exportData.waterIntakes.isEmpty && 
               exportData.gameScores.isEmpty {
                print("⚠️ No user data found - export will show empty report")
            }
            
            return exportData
        } catch {
            print("❌ Error fetching data: \(error)")
            throw error
        }
    }
    
    // MARK: - Data Deletion
    func deleteAllUserData(context: ModelContext) throws {
        // Delete all data from all models
        let habitDescriptor = FetchDescriptor<HabitItem>()
        let habits = try context.fetch(habitDescriptor)
        habits.forEach { context.delete($0) }
        
        let todoDescriptor = FetchDescriptor<TodoItem>()
        let todos = try context.fetch(todoDescriptor)
        todos.forEach { context.delete($0) }
        
        let medicationDescriptor = FetchDescriptor<MedicationEntry>()
        let medications = try context.fetch(medicationDescriptor)
        medications.forEach { context.delete($0) }
        
        let waterDescriptor = FetchDescriptor<WaterIntake>()
        let waterIntakes = try context.fetch(waterDescriptor)
        waterIntakes.forEach { context.delete($0) }
        
        let gameScoreDescriptor = FetchDescriptor<GameScore>()
        let gameScores = try context.fetch(gameScoreDescriptor)
        gameScores.forEach { context.delete($0) }
        
        try context.save()
        
        // Clear UserDefaults settings
        clearUserDefaults()
    }
    
    private func clearUserDefaults() {
        let defaults = UserDefaults.standard
        let keys = [
            "isDarkMode", "selectedLanguage", "notificationsEnabled",
            "soundEffectsEnabled", "hapticFeedbackEnabled", "defaultReminderTimeData",
            "dailyWaterGoal", "streakCelebrationEnabled", "showStreakInfo", "autoResetTimeData",
            "memoryGameDefaultSize", "hasRunStreakMigration", "lastResetDate"
        ]
        
        keys.forEach { defaults.removeObject(forKey: $0) }
    }
    
    // MARK: - Helper Properties
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: Date())
    }
}

// MARK: - Export Format
enum ExportFormat: String, CaseIterable {
    case json = "JSON"
    case pdf = "Text Report"
    
    var fileExtension: String {
        switch self {
        case .json: return "json"
        case .pdf: return "txt"
        }
    }
}

// MARK: - Export Data Models
struct ExportData: Codable {
    let exportDate: Date
    let appVersion: String
    let habits: [ExportHabit]
    let todos: [ExportTodo]
    let medications: [ExportMedication]
    let waterIntakes: [ExportWaterIntake]
    let gameScores: [ExportGameScore]
}

struct ExportHabit: Codable {
    let title: String
    let notes: String?
    let frequency: String
    let targetCount: Int
    let currentCount: Int
    let isCompleted: Bool
    let reminderTime: Date?
    let createdAt: Date
    let currentStreak: Int
    let longestStreak: Int
    let lastCompletedDate: Date?
    
    init(from habit: HabitItem) {
        self.title = habit.title
        self.notes = habit.notes
        self.frequency = habit.frequency.rawValue
        self.targetCount = habit.targetCount
        self.currentCount = habit.currentCount
        self.isCompleted = habit.isCompleted
        self.reminderTime = habit.reminderTime
        self.createdAt = habit.createdAt
        self.currentStreak = habit.currentStreak
        self.longestStreak = habit.longestStreak
        self.lastCompletedDate = habit.lastCompletedDate
    }
}

struct ExportTodo: Codable {
    let title: String
    let notes: String?
    let isCompleted: Bool
    let priority: String
    let dueDate: Date?
    let createdAt: Date
    
    init(from todo: TodoItem) {
        self.title = todo.title
        self.notes = todo.notes
        self.isCompleted = todo.isCompleted
        self.priority = todo.priority.rawValue
        self.dueDate = todo.dueDate
        self.createdAt = todo.createdAt
    }
}

struct ExportMedication: Codable {
    let medicationName: String
    let dosage: String
    let frequency: String
    let isActive: Bool
    let createdAt: Date
    
    init(from medication: MedicationEntry) {
        self.medicationName = medication.medicationName
        self.dosage = medication.dosage
        self.frequency = medication.frequency.rawValue
        self.isActive = medication.isActive
        self.createdAt = medication.createdAt
    }
}

struct ExportWaterIntake: Codable {
    let date: Date
    let dailyGoal: Int
    let amount: Int
    
    // Computed glass count for export compatibility
    var glassCount: Int {
        return Int(ceil(Double(amount) / 250.0))
    }
    
    init(from waterIntake: WaterIntake) {
        self.date = waterIntake.date
        self.dailyGoal = waterIntake.dailyGoal
        self.amount = waterIntake.amount
    }
}

struct ExportGameScore: Codable {
    let gridSize: Int
    let moves: Int
    let timeInSeconds: Int
    let score: Int
    let date: Date
    
    init(from gameScore: GameScore) {
        self.gridSize = gameScore.gridSize
        self.moves = gameScore.moves
        self.timeInSeconds = gameScore.timeInSeconds
        self.score = gameScore.score
        self.date = gameScore.date
    }
}