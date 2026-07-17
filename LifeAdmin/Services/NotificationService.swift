import Foundation
import UserNotifications
import Combine

@MainActor
final class NotificationService: ObservableObject {
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus

        guard settings.authorizationStatus == .notDetermined else { return }

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            let latest = await center.notificationSettings()
            authorizationStatus = latest.authorizationStatus
            _ = granted
        } catch {
            authorizationStatus = .denied
        }
    }

    func schedule(taskId: UUID, title: String, at date: Date) async {
        let content = UNMutableNotificationContent()
        content.title = "Reminder"
        content.body = title
        content.sound = .default
        content.userInfo = ["taskId": taskId.uuidString]

        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(
            identifier: "task-\(taskId.uuidString)",
            content: content,
            trigger: trigger
        )

        try? await UNUserNotificationCenter.current().add(request)
    }

    func cancel(taskId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["task-\(taskId.uuidString)"]
        )
    }
}
