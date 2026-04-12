import Foundation
import CloudKit
import SwiftUI

@MainActor
class SharingViewModel: ObservableObject {
    private let cloudKitService = CloudKitService.shared
    private let loc = LocalizationManager()

    @Published var isSharing = false
    @Published var shareError: String?
    @Published var sharedBooks: [CKShare] = []

    func createSharedBook(name: String, icon: String) async -> Book? {
        guard let persistenceController = ServiceLocator.shared.persistenceController else { return nil }

        isSharing = true
        shareError = nil

        do {
            let accountStatus = await cloudKitService.checkAccountStatus()
            guard accountStatus == .available else {
                shareError = loc["service.signInICloud"]
                isSharing = false
                return nil
            }

            let context = persistenceController.viewContext
            let book = Book.create(in: context, name: name, icon: icon, type: .shared)
            Category.createDefaultCategories(for: book, in: context)
            let _ = Member.create(in: context, name: loc["common.me"], book: book, role: .owner)
            persistenceController.save()

            let zone = try await cloudKitService.createSharedBookZone(bookId: book.id)
            let rootRecord = try await cloudKitService.createBookRecord(book: book, in: zone)
            let _ = try await cloudKitService.createShare(for: rootRecord, in: zone)

            isSharing = false
            return book
        } catch {
            shareError = error.localizedDescription
            isSharing = false
            return nil
        }
    }

    func getCloudSharingController(for book: Book) -> UICloudSharingController? {
        guard book.bookType == .shared else { return nil }

        let zoneId = CKRecordZone.ID(
            zoneName: "BookZone_\(book.id.uuidString)",
            ownerName: CKCurrentUserDefaultName
        )

        let container = CKContainer(identifier: "iCloud.com.bookkeeper.app")

        return nil
    }

    func handleShareAcceptance(metadata: CKShare.Metadata) async {
        do {
            try await cloudKitService.acceptShare(metadata: metadata)
        } catch {
            shareError = error.localizedDescription
        }
    }
}

final class ServiceLocator {
    static let shared = ServiceLocator()

    weak var persistenceController: PersistenceController?

    private init() {}
}
