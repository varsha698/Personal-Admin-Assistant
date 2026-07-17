import Foundation
import SwiftData

enum PersistenceSetup {
    static func makeContainer() -> ModelContainer {
        let schema = Schema([
            Task.self,
            Commitment.self,
            DailyBrief.self,
            ActionReceipt.self
        ])

        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
