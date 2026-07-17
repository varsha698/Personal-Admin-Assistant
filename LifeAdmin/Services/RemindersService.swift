import Foundation
import EventKit

@MainActor
final class RemindersService {
    private let store = EKEventStore()

    func requestAccess() async -> Bool {
        do {
            return try await store.requestFullAccessToReminders()
        } catch {
            return false
        }
    }

    func upsert(task: Task) async -> String? {
        guard await requestAccess() else { return nil }

        let reminder: EKReminder
        if let existingId = task.eventKitId,
           let found = store.calendarItem(withIdentifier: existingId) as? EKReminder {
            reminder = found
        } else {
            reminder = EKReminder(eventStore: store)
            reminder.calendar = store.defaultCalendarForNewReminders()
        }

        reminder.title = task.title
        reminder.notes = task.notes
        reminder.isCompleted = task.status == .done
        reminder.priority = mapPriority(task.priority)

        if let due = task.due {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: due
            )
        } else {
            reminder.dueDateComponents = nil
        }

        do {
            try store.save(reminder, commit: true)
            return reminder.calendarItemIdentifier
        } catch {
            return nil
        }
    }

    func delete(eventKitId: String) async {
        guard await requestAccess() else { return }
        guard let reminder = store.calendarItem(withIdentifier: eventKitId) as? EKReminder else { return }
        try? store.remove(reminder, commit: true)
    }

    private func mapPriority(_ p: Priority) -> Int {
        switch p {
        case .urgent: 1
        case .high: 3
        case .normal: 5
        case .low: 7
        }
    }
}
