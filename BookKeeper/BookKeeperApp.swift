import SwiftUI

@main
struct LedgerlyApp: App {
    @StateObject private var bookVM = BookViewModel()

    init() {
        PersistenceController.shared.seedDemoDataIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, PersistenceController.shared.viewContext)
                .environmentObject(bookVM)
                .task {
                    ServiceLocator.shared.persistenceController = PersistenceController.shared
                    _ = await NotificationService.shared.requestAuthorization()
                }
        }
    }
}
