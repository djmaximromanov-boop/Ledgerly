import SwiftUI

@main
struct LedgerlyApp: App {
    @StateObject private var bookVM = BookViewModel()
    @StateObject private var locManager = LocalizationManager()

    init() {
        PersistenceController.shared.seedDemoDataIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, PersistenceController.shared.viewContext)
                .environmentObject(bookVM)
                .environmentObject(locManager)
                .task {
                    ServiceLocator.shared.persistenceController = PersistenceController.shared
                    _ = await NotificationService.shared.requestAuthorization()
                }
        }
    }
}
