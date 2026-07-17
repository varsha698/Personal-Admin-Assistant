import Foundation
import SwiftData

@Model
final class Task {
    @Attribute(.unique) var id: UUID
    var title: String
    var notes: String?
    var due: Date?
    var priorityRaw: Int
    var statusRaw: String
    var sourceRaw: String
    var sourceRef: String?
    var eventKitId: String?
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .nullify, inverse: \Commitment.task)
    var commitment: Commitment?

    init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        due: Date? = nil,
        priority: Priority = .normal,
        status: Status = .open,
        source: Source = .manual,
        sourceRef: String? = nil,
        eventKitId: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.due = due
        self.priorityRaw = priority.rawValue
        self.statusRaw = status.rawValue
        self.sourceRaw = source.rawValue
        self.sourceRef = sourceRef
        self.eventKitId = eventKitId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var priority: Priority {
        get { Priority(rawValue: priorityRaw) ?? .normal }
        set { priorityRaw = newValue.rawValue; updatedAt = .now }
    }

    var status: Status {
        get { Status(rawValue: statusRaw) ?? .open }
        set { statusRaw = newValue.rawValue; updatedAt = .now }
    }

    var source: Source {
        get { Source(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }
}

enum Priority: Int, Codable, CaseIterable {
    case low = 0, normal = 1, high = 2, urgent = 3
    var label: String {
        switch self {
        case .low: "Low"; case .normal: "Normal"; case .high: "High"; case .urgent: "Urgent"
        }
    }
}

enum Status: String, Codable, CaseIterable {
    case open, done, snoozed
    var label: String { rawValue.capitalized }
}

enum Source: String, Codable {
    case manual, capture, email, calendar, reminders
}
