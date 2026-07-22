import SwiftUI
import SwiftData

struct InboxView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var notifications: NotificationService

    private let reminders = RemindersService()

    @Query(
        filter: #Predicate<Commitment> { $0.approvalRaw == "pending" },
        sort: \Commitment.createdAt,
        order: .reverse
    )
    private var pending: [Commitment]

    var body: some View {
        NavigationStack {
            List {
                ForEach(pending) { commitment in
                    CommitmentCard(commitment: commitment, onApprove: {
                        approve(commitment)
                    }, onDismiss: {
                        dismiss(commitment)
                    })
                }
            }
            .navigationTitle("Inbox")
            .overlay {
                if pending.isEmpty {
                    ContentUnavailableView(
                        "No pending items",
                        systemImage: "tray",
                        description: Text("Extracted commitments will appear here for your approval.")
                    )
                }
            }
        }
    }

    private func approve(_ commitment: Commitment) {
        let task = Task(
            title: commitment.summary,
            due: commitment.due,
            priority: commitment.kind == .bill || commitment.kind == .deadline ? .high : .normal,
            source: .email,
            sourceRef: commitment.evidenceSourceRef
        )
        commitment.task = task
        commitment.approval = .approved
        context.insert(task)

        context.insert(ActionReceipt(
            action: "approved commitment",
            target: commitment.summary,
            wasUserApproved: true
        ))
        try? context.save()

        _Concurrency.Task {
            if let due = commitment.due {
                await notifications.schedule(taskId: task.id, title: task.title, at: due)
            }
            let ekId = await reminders.upsert(task: task)
            if let ekId {
                task.eventKitId = ekId
                try? context.save()
            }
        }
    }

    private func dismiss(_ commitment: Commitment) {
        commitment.approval = .dismissed
        context.insert(ActionReceipt(
            action: "dismissed commitment",
            target: commitment.summary,
            wasUserApproved: true
        ))
        try? context.save()
    }
}

struct CommitmentCard: View {
    let commitment: Commitment
    let onApprove: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerRow
            Text(commitment.summary).font(.body)
            dueRow
            amountRow
            evidenceDisclosure
            actionRow
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var headerRow: some View {
        HStack {
            Label(commitment.kind.label, systemImage: kindIcon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(Int(commitment.confidence * 100))%")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var dueRow: some View {
        if let due = commitment.due {
            Label(due.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                .font(.caption)
                .foregroundStyle(due < .now ? Color.red : Color.primary)
        }
    }

    @ViewBuilder
    private var amountRow: some View {
        if let amount = commitment.amount, let currency = commitment.currencyCode {
            Label("\(currency) \(amount.formatted())", systemImage: "dollarsign.circle")
                .font(.caption)
        }
    }

    @ViewBuilder
    private var evidenceDisclosure: some View {
        DisclosureGroup("Evidence") {
            Text(commitment.evidenceText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var actionRow: some View {
        HStack {
            Button("Dismiss", role: .destructive, action: onDismiss)
                .buttonStyle(.bordered)
            Spacer()
            Button("Approve", action: onApprove)
                .buttonStyle(.borderedProminent)
        }
        .padding(.top, 4)
    }

    private var kindIcon: String {
        switch commitment.kind {
        case .bill: "dollarsign.circle"
        case .appointment: "calendar"
        case .followUp: "arrow.uturn.right.circle"
        case .deadline: "exclamationmark.triangle"
        case .delivery: "shippingbox"
        }
    }
}
