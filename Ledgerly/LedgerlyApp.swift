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
                    FinanceWidgetSnapshotService.refresh(
                        book: bookVM.currentBook,
                        context: PersistenceController.shared.viewContext
                    )
                    _ = await NotificationService.shared.requestAuthorization()
                }
                .onChange(of: bookVM.currentBook?.id) { _, _ in
                    FinanceWidgetSnapshotService.refresh(
                        book: bookVM.currentBook,
                        context: PersistenceController.shared.viewContext
                    )
                }
                .onReceive(NotificationCenter.default.publisher(
                    for: .NSManagedObjectContextDidSave,
                    object: PersistenceController.shared.viewContext
                )) { _ in
                    FinanceWidgetSnapshotService.refresh(
                        book: bookVM.currentBook,
                        context: PersistenceController.shared.viewContext
                    )
                }
        }
    }
}
