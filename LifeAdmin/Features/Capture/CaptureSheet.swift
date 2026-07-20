import SwiftUI
import SwiftData

struct CaptureSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var notifications: NotificationService

    @State private var text: String = ""
    @State private var dueDate: Date = Date().addingTimeInterval(3600)
    @State private var hasDueDate: Bool = false
    @State private var priority: Priority = .normal

    private let reminders = RemindersService()

    var body: some View {
        NavigationStack {
            Form {
                Section("What needs doing?") {
                    TextField("e.g. Pay Con Ed $84 by Friday", text: $text, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("When") {
                    Toggle("Has due date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Due", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }

                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(Priority.allCases, id: \.self) { p in
                            Text(p.label).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if !text.isEmpty {
                    Section("Preview") {
                        let extracted = CommitmentExtractor.extract(from: text)
                        if let d = extracted.due {
                            Label(d.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                                .font(.caption)
                        }
                        if let a = extracted.amount, let c = extracted.currencyCode {
                            Label("\(c) \(a.formatted())", systemImage: "dollarsign.circle")
                                .font(.caption)
                        }
                        Label("Confidence \(Int(extracted.confidence * 100))%", systemImage: "chart.bar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("New task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onChange(of: text) { _, newValue in
                if !hasDueDate {
                    if let d = CommitmentExtractor.extract(from: newValue).due {
                        dueDate = d
                        hasDueDate = true
                    }
                }
            }
        }
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let task = Task(
            title: trimmed,
            due: hasDueDate ? dueDate : nil,
            priority: priority,
            source: .capture
        )
        context.insert(task)
        try? context.save()

        _Concurrency.Task {
            if hasDueDate {
                await notifications.schedule(taskId: task.id, title: task.title, at: dueDate)
            }
            let ekId = await reminders.upsert(task: task)
            if let ekId {
                task.eventKitId = ekId
                try? context.save()
            }
        }

        dismiss()
    }
}
