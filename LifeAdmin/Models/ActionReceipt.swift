import Foundation
import SwiftData

@Model
final class ActionReceipt {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var action: String
    var target: String
    var wasUserApproved: Bool
    var detail: String?

    init(
        id: UUID = UUID(),
        timestamp: Date = .now,
        action: String,
        target: String,
        wasUserApproved: Bool,
        detail: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.action = action
        self.target = target
        self.wasUserApproved = wasUserApproved
        self.detail = detail
    }
}
