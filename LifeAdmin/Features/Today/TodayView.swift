import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @State private var agenda: [AgendaItem] = []
    @State private var showCapture = false

    private let calendarService = CalendarService()

    @Query(
        filter: #Predicate<Task> { $0.statusRaw == "open" },
        sort: [SortDescriptor(\Task.due, order: .forward)]
    )
    private var openTasks: [Task]

    var tasksDueToday: [Task] {
        let end = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: .now))!
        return openTasks.filter { ($0.due ?? .distantFuture) < end }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Agenda") {
                    if agenda.isEmpty {
                        Text("Nothing on the calendar today.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(agenda) { item in
                            AgendaRow(item: item)
                        }
                    }
                }

                Section("Due today") {
                    if tasksDueToday.isEmpty {
                        Text("All caught up.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(tasksDueToday) { task in
                            TaskRow(task: task)
                        }
                    }
                }
            }
            .navigationTitle("Today")
            .toolbar {
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
            .task {
                agenda = await calendarService.agenda(for: .now)
            }
            .refreshable {
                agenda = await calendarService.agenda(for: .now)
            }
        }
    }
}

struct AgendaRow: View {
    let item: AgendaItem

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Text(timeString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 90, alignment: .leading)

            VStack(alignment: .leading) {
                Text(item.title).font(.body)
                if let loc = item.location, !loc.isEmpty {
                    Text(loc).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    var timeString: String {
        if item.isAllDay { return "All-day" }
        let f = DateFormatter()
        f.timeStyle = .short
        return "\(f.string(from: item.start)) – \(f.string(from: item.end))"
    }
}
