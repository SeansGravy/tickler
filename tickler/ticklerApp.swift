import SwiftUI

@main
struct ticklerApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            DropdownView()
                .environmentObject(appState)
        } label: {
            MenuBarView(appState: appState)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(appState)
        }

        Window("Manage Symbols", id: "symbols") {
            SymbolListView()
                .environmentObject(appState)
        }
        .windowResizability(.contentSize)
    }
}
