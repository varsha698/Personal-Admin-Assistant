import Foundation
import EventKit

struct AgendaItem: Identifiable, Hashable {
    let id: String
    let title: String
    let start: Date
    let end: Date
    let location: String?
    let isAllDay: Bool
}

@MainActor
final class CalendarService {
    private let store = EKEventStore()

    func requestAccess() async -> Bool {
        do {
            return try await store.requestFullAccessToEvents()
        } catch {
            return false
        }
    }

    func agenda(for date: Date) async -> [AgendaItem] {
        guard await requestAccess() else { return [] }

        let start = Calendar.current.startOfDay(for: date)
        guard let end = Calendar.current.date(byAdding: .day, value: 1, to: start) else { return [] }

        let predicate = store.predicateForEvents(
            withStart: start,
            end: end,
            calendars: nil
        )

        return store.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }
            .map {
                AgendaItem(
                    id: $0.eventIdentifier,
                    title: $0.title ?? "(no title)",
                    start: $0.startDate,
                    end: $0.endDate,
                    location: $0.location,
                    isAllDay: $0.isAllDay
                )
            }
    }
}
