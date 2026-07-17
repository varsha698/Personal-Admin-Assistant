import Foundation
import SwiftData

@Model
final class Commitment {
    @Attribute(.unique) var id: UUID
    var summary: String
    var kindRaw: String
    var due: Date?
    var amount: Decimal?
    var currencyCode: String?
    var confidence: Double
    var evidenceText: String
    var evidenceSourceRef: String
    var approvalRaw: String
    var createdAt: Date

    @Relationship(deleteRule: .nullify)
    var task: Task?

    init(
        id: UUID = UUID(),
        summary: String,
        kind: Kind,
        due: Date? = nil,
        amount: Decimal? = nil,
        currencyCode: String? = nil,
        confidence: Double = 0.5,
        evidenceText: String,
        evidenceSourceRef: String,
        approval: Approval = .pending,
        createdAt: Date = .now
    ) {
        self.id = id
        self.summary = summary
        self.kindRaw = kind.rawValue
        self.due = due
        self.amount = amount
        self.currencyCode = currencyCode
        self.confidence = confidence
        self.evidenceText = evidenceText
        self.evidenceSourceRef = evidenceSourceRef
        self.approvalRaw = approval.rawValue
        self.createdAt = createdAt
    }

    var kind: Kind {
        get { Kind(rawValue: kindRaw) ?? .followUp }
        set { kindRaw = newValue.rawValue }
    }

    var approval: Approval {
        get { Approval(rawValue: approvalRaw) ?? .pending }
        set { approvalRaw = newValue.rawValue }
    }

    enum Kind: String, Codable, CaseIterable {
        case bill, appointment, followUp, deadline, delivery
        var label: String {
            switch self {
            case .bill: "Bill"
            case .appointment: "Appointment"
            case .followUp: "Follow-up"
            case .deadline: "Deadline"
            case .delivery: "Delivery"
            }
        }
    }

    enum Approval: String, Codable {
        case pending, approved, dismissed
    }
}
