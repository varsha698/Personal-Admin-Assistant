import SwiftUI
import SwiftData

struct TaskRow: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var notifications: NotificationService
    @Bindable var task: Task

    private let reminders = RemindersService()

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                toggleDone()
            } label: {
                Image(systemName: task.status == .done ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.status == .done ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .strikethrough(task.status == .done)
                    .foregroundStyle(task.status == .done ? .secondary : .primary)

                HStack(spacing: 8) {
                    if let due = task.due {
                        Label(dueString(due), systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(dueColor(due))
                    }
                    if task.priority != .normal {
                        Label(task.priority.label, systemImage: "flag.fill")
                            .font(.caption)
                            .foregroundStyle(priorityColor(task.priority))
                    }
                    if task.source != .manual && task.source != .capture {
                        Label(task.source.rawValue, systemImage: "link")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }

    private func toggleDone() {
        task.status = task.status == .done ? .open : .done
        try? context.save()

        if task.status == .done {
            notifications.cancel(taskId: task.id)
        }
        _Concurrency.Task {
            _ = await reminders.upsert(task: task)
        }
    }

    private func dueString(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            let f = DateFormatter(); f.timeStyle = .short
            return "Today \(f.string(from: date))"
        }
        if cal.isDateInTomorrow(date) {
            let f = DateFormatter(); f.timeStyle = .short
            return "Tomorrow \(f.string(from: date))"
        }
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .short
        return f.string(from: date)
    }

    private func dueColor(_ date: Date) -> Color {
        if date < .now { return .red }
        if Calendar.current.isDateInToday(date) { return .orange }
        return .secondary
    }

    private func priorityColor(_ p: Priority) -> Color {
        switch p {
        case .urgent: .red
        case .high: .orange
        case .normal: .secondary
        case .low: .gray
        }
    }
}
