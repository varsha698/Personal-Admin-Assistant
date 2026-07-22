import SwiftUI
import SwiftData
import EventKit
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var notifications: NotificationService

    @State private var calendarStatus: EKAuthorizationStatus = .notDetermined
    @State private var remindersStatus: EKAuthorizationStatus = .notDetermined

    @Query private var allTasks: [Task]
    @Query private var allCommitments: [Commitment]
    @Query(sort: [SortDescriptor(\ActionReceipt.timestamp, order: .reverse)]) private var receipts: [ActionReceipt]

    var body: some View {
        NavigationStack {
            List {
                Section("Permissions") {
                    permissionRow(
                        title: "Notifications",
                        granted: notifications.authorizationStatus == .authorized,
                        detail: authLabel(notifications.authorizationStatus)
                    )
                    permissionRow(
                        title: "Calendar",
                        granted: calendarStatus == .fullAccess,
                        detail: ekLabel(calendarStatus)
                    )
                    permissionRow(
                        title: "Reminders",
                        granted: remindersStatus == .fullAccess,
                        detail: ekLabel(remindersStatus)
                    )
                    Button("Open iOS Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }

                Section("Data") {
                    LabeledContent("Tasks", value: "\(allTasks.count)")
                    LabeledContent("Commitments", value: "\(allCommitments.count)")
                    LabeledContent("Action receipts", value: "\(receipts.count)")
                }

                Section("Recent actions") {
                    if receipts.isEmpty {
                        Text("No actions yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(receipts.prefix(10)) { receipt in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(receipt.action).font(.caption)
                                Text(receipt.target).font(.caption2).foregroundStyle(.secondary)
                                Text(receipt.timestamp.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: appVersion)
                    LabeledContent("Storage", value: "Local (on device)")
                    LabeledContent("AI", value: "On-device (Foundation Models)")
                }
            }
            .navigationTitle("Settings")
            .task {
                refreshStatuses()
            }
            .onAppear {
                refreshStatuses()
            }
        }
    }

    private func permissionRow(title: String, granted: Bool, detail: String) -> some View {
        HStack {
            Image(systemName: granted ? "checkmark.circle.fill" : "exclamationmark.circle")
                .foregroundStyle(granted ? .green : .orange)
            VStack(alignment: .leading) {
                Text(title)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func refreshStatuses() {
        calendarStatus = EKEventStore.authorizationStatus(for: .event)
        remindersStatus = EKEventStore.authorizationStatus(for: .reminder)
    }

    private func authLabel(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .authorized: "Authorized"
        case .denied: "Denied — enable in iOS Settings"
        case .notDetermined: "Not requested yet"
        case .provisional: "Provisional"
        case .ephemeral: "Ephemeral"
        @unknown default: "Unknown"
        }
    }

    private func ekLabel(_ status: EKAuthorizationStatus) -> String {
        switch status {
        case .fullAccess: "Full access"
        case .writeOnly: "Write only"
        case .authorized: "Authorized"
        case .denied: "Denied — enable in iOS Settings"
        case .restricted: "Restricted"
        case .notDetermined: "Not requested yet"
        @unknown default: "Unknown"
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        return "\(v) (\(b))"
    }
}
