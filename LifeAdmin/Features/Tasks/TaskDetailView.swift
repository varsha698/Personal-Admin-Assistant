import SwiftUI
import SwiftData

struct TaskDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var notifications: NotificationService
    @Bindable var task: Task

    private let reminders = RemindersService()

    var body: some View {
        Form {
            Section("Title") {
                TextField("Title", text: $task.title, axis: .vertical)
                    .lineLimit(1...4)
            }

            Section("Notes") {
                TextField("Notes", text: Binding(
                    get: { task.notes ?? "" },
                    set: { task.notes = $0.isEmpty ? nil : $0 }
                ), axis: .vertical)
                .lineLimit(2...8)
            }

            Section("Due") {
                DatePicker(
                    "Due",
                    selection: Binding(
                        get: { task.due ?? Date() },
                        set: { task.due = $0 }
                    ),
                    displayedComponents: [.date, .hourAndMinute]
                )
                if task.due != nil {
                    Button("Clear due date", role: .destructive) {
                        task.due = nil
                    }
                }
            }

            Section("Priority") {
                Picker("Priority", selection: Binding(
                    get: { task.priority },
                    set: { task.priority = $0 }
                )) {
                    ForEach(Priority.allCases, id: \.self) { p in
                        Text(p.label).tag(p)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Status") {
                Picker("Status", selection: Binding(
                    get: { task.status },
                    set: { task.status = $0 }
                )) {
                    ForEach(Status.allCases, id: \.self) { s in
                        Text(s.label).tag(s)
                    }
                }
                .pickerStyle(.segmented)
            }

            if let commitment = task.commitment {
                Section("Source") {
                    LabeledContent("Kind", value: commitment.kind.label)
                    Text(commitment.evidenceText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button("Delete task", role: .destructive) {
                    delete()
                }
            }
        }
        .navigationTitle("Task")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            try? context.save()
            notifications.cancel(taskId: task.id)
            let shouldReschedule = task.status == .open && task.due != nil
            _Concurrency.Task {
                if shouldReschedule, let due = task.due {
                    await notifications.schedule(taskId: task.id, title: task.title, at: due)
                }
                let ekId = await reminders.upsert(task: task)
                if let ekId, task.eventKitId != ekId {
                    task.eventKitId = ekId
                    try? context.save()
                }
            }
        }
    }

    private func delete() {
        let ekId = task.eventKitId
        let taskId = task.id
        notifications.cancel(taskId: taskId)
        context.delete(task)
        try? context.save()
        if let ekId {
            _Concurrency.Task { await reminders.delete(eventKitId: ekId) }
        }
        dismiss()
    }
}
