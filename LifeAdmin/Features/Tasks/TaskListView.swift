import SwiftUI
import SwiftData
import UserNotifications

struct TaskListView: View {
    @Environment(\.modelContext) private var context
    @State private var showCapture = false
    @State private var filter: Filter = .open

    enum Filter: String, CaseIterable, Identifiable {
        case open, done, all
        var id: String { rawValue }
        var label: String { rawValue.capitalized }
    }

    @Query(sort: [SortDescriptor(\Task.due, order: .forward), SortDescriptor(\Task.createdAt, order: .reverse)])
    private var allTasks: [Task]

    private var filtered: [Task] {
        switch filter {
        case .open: allTasks.filter { $0.status == .open }
        case .done: allTasks.filter { $0.status == .done }
        case .all: allTasks
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered) { task in
                    NavigationLink(value: task) {
                        TaskRow(task: task)
                    }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Tasks")
            .navigationDestination(for: Task.self) { task in
                TaskDetailView(task: task)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Picker("Filter", selection: $filter) {
                        ForEach(Filter.allCases) { f in
                            Text(f.label).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCapture = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCapture) {
                CaptureSheet()
            }
            .overlay {
                if filtered.isEmpty {
                    ContentUnavailableView(
                        emptyTitle,
                        systemImage: "tray",
                        description: Text("Tap + to add a task.")
                    )
                }
            }
        }
    }

    private var emptyTitle: String {
        switch filter {
        case .open: "No open tasks"
        case .done: "Nothing completed yet"
        case .all: "No tasks yet"
        }
    }

    private func delete(at offsets: IndexSet) {
        let reminders = RemindersService()
        for index in offsets {
            let task = filtered[index]
            let ekId = task.eventKitId
            let taskId = task.id
            context.delete(task)
            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: ["task-\(taskId.uuidString)"]
            )
            if let ekId {
                _Concurrency.Task { await reminders.delete(eventKitId: ekId) }
            }
        }
        try? context.save()
    }
}
