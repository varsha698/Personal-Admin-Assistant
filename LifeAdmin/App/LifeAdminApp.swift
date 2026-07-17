import SwiftUI
import SwiftData

@main
struct LifeAdminApp: App {
    let container: ModelContainer = PersistenceSetup.makeContainer()

    @StateObject private var notifications = NotificationService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(container)
                .environmentObject(notifications)
                .task {
                    await notifications.requestAuthorizationIfNeeded()
                }
        }
    }
}
