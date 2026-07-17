import Foundation

/// Deterministic first-pass extractor for dates and amounts from free-form text.
/// Foundation Models fallback is added in Phase 2.
struct ExtractedCommitment {
    var summary: String
    var due: Date?
    var amount: Decimal?
    var currencyCode: String?
    var confidence: Double
}

enum CommitmentExtractor {
    static func extract(from text: String, referenceDate: Date = .now) -> ExtractedCommitment {
        let due = firstDate(in: text, referenceDate: referenceDate)
        let (amount, currency) = firstAmount(in: text)

        var confidence = 0.3
        if due != nil { confidence += 0.35 }
        if amount != nil { confidence += 0.25 }

        return ExtractedCommitment(
            summary: text.trimmingCharacters(in: .whitespacesAndNewlines),
            due: due,
            amount: amount,
            currencyCode: currency,
            confidence: min(confidence, 0.95)
        )
    }

    private static func firstDate(in text: String, referenceDate: Date) -> Date? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        let range = NSRange(text.startIndex..., in: text)
        let match = detector?.firstMatch(in: text, range: range)
        return match?.date
    }

    private static func firstAmount(in text: String) -> (Decimal?, String?) {
        let pattern = #"([$€£])\s?([0-9]+(?:\.[0-9]{1,2})?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return (nil, nil) }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              match.numberOfRanges == 3,
              let symbolRange = Range(match.range(at: 1), in: text),
              let numberRange = Range(match.range(at: 2), in: text),
              let amount = Decimal(string: String(text[numberRange])) else {
            return (nil, nil)
        }
        let currency: String = switch text[symbolRange] {
        case "$": "USD"
        case "€": "EUR"
        case "£": "GBP"
        default: "USD"
        }
        return (amount, currency)
    }
}
