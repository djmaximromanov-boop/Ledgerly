import SwiftUI

@main
struct LedgerlyApp: App {
    @AppStorage("currency") private var currency = "RUB"
    @StateObject private var bookVM = BookViewModel()
    @StateObject private var locManager = LocalizationManager()

    init() {
        #if targetEnvironment(simulator)
        PersistenceController.shared.seedDemoDataIfNeeded()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, Locale(identifier: "\(locManager.language.locale.identifier)@currency=\(currency)"))
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
