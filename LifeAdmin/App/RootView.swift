import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max") }

            InboxView()
                .tabItem { Label("Inbox", systemImage: "tray") }

            TaskListView()
                .tabItem { Label("Tasks", systemImage: "checklist") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(PersistenceSetup.makeContainer())
}
