import Foundation
import SwiftData

@Model
final class DailyBrief {
    @Attribute(.unique) var dateKey: String
    var body: String
    var updatedAt: Date

    init(date: Date, body: String, updatedAt: Date = .now) {
        self.dateKey = DailyBrief.key(for: date)
        self.body = body
        self.updatedAt = updatedAt
    }

    static func key(for date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
