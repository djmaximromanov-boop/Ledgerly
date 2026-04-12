import Foundation
import CloudKit

actor CloudKitService {
    static let shared = CloudKitService()

    private let container: CKContainer
    private let privateDatabase: CKDatabase

    private init() {
        container = CKContainer(identifier: "iCloud.com.bookkeeper.app")
        privateDatabase = container.privateCloudDatabase
    }

    func checkAccountStatus() async -> CKAccountStatus {
        await withCheckedContinuation { continuation in
            container.accountStatus { status, _ in
                continuation.resume(returning: status)
            }
        }
    }

    func createSharedBookZone(bookId: UUID) async throws -> CKRecordZone {
        let zoneId = CKRecordZone.ID(
            zoneName: "BookZone_\(bookId.uuidString)",
            ownerName: CKCurrentUserDefaultName
        )
        let zone = CKRecordZone(zoneID: zoneId)
        try await privateDatabase.save(zone)
        return zone
    }

    func createBookRecord(book: Book, in zone: CKRecordZone) async throws -> CKRecord {
        let recordId = CKRecord.ID(recordName: book.id.uuidString, zoneID: zone.zoneID)
        let record = CKRecord(recordType: "Book", recordID: recordId)
        record["name"] = book.name as CKRecordValue
        record["icon"] = book.icon as CKRecordValue
        record["type"] = book.type as CKRecordValue
        record["currency"] = book.currency as CKRecordValue
        record["createdAt"] = book.createdAt as CKRecordValue
        try await privateDatabase.save(record)
        return record
    }

    func createShare(for rootRecord: CKRecord, in zone: CKRecordZone) async throws -> CKShare {
        let share = CKShare(recordZoneID: zone.zoneID)
        let fallbackTitle = LocalizationManager.localized("service.sharedLedger")
        share[CKShare.SystemFieldKey.title] = (rootRecord["name"] as? String ?? fallbackTitle) as CKRecordValue
        share[CKShare.SystemFieldKey.shareType] = "com.bookkeeper.shared-book" as CKRecordValue
        share.publicPermission = .readOnly

        try await privateDatabase.modifyRecords(saving: [rootRecord, share], deleting: [])
        return share
    }

    func fetchShare(for zone: CKRecordZone.ID) async throws -> CKShare? {
        let shareRecordId = CKRecord.ID(recordName: CKRecordNameZoneWideShare, zoneID: zone)
        do {
            let record = try await privateDatabase.record(for: shareRecordId)
            return record as? CKShare
        } catch {
            return nil
        }
    }

    func addParticipant(to share: CKShare, permission: CKShare.ParticipantPermission) {
        share.publicPermission = permission
    }

    func saveTransaction(_ transaction: Transaction, bookId: UUID) async throws {
        let zoneId = CKRecordZone.ID(
            zoneName: "BookZone_\(bookId.uuidString)",
            ownerName: CKCurrentUserDefaultName
        )
        let recordId = CKRecord.ID(recordName: transaction.id.uuidString, zoneID: zoneId)
        let record = CKRecord(recordType: "Transaction", recordID: recordId)
        record["amount"] = transaction.amount as CKRecordValue
        record["type"] = transaction.type as CKRecordValue
        record["note"] = (transaction.note ?? "") as CKRecordValue
        record["date"] = transaction.date as CKRecordValue
        record["createdAt"] = transaction.createdAt as CKRecordValue
        record["updatedAt"] = transaction.updatedAt as CKRecordValue

        if let categoryId = transaction.category?.id {
            record["categoryId"] = categoryId.uuidString as CKRecordValue
        }
        if let memberId = transaction.member?.id {
            record["memberId"] = memberId.uuidString as CKRecordValue
        }

        try await privateDatabase.save(record)
    }

    func deleteTransaction(_ transactionId: UUID, bookId: UUID) async throws {
        let zoneId = CKRecordZone.ID(
            zoneName: "BookZone_\(bookId.uuidString)",
            ownerName: CKCurrentUserDefaultName
        )
        let recordId = CKRecord.ID(recordName: transactionId.uuidString, zoneID: zoneId)
        try await privateDatabase.deleteRecord(withID: recordId)
    }

    func fetchSharedZones() async throws -> [CKRecordZone] {
        let allZones = try await privateDatabase.allRecordZones()
        return allZones.filter { $0.zoneID.zoneName.hasPrefix("BookZone_") }
    }

    func acceptShare(metadata: CKShare.Metadata) async throws {
        try await container.accept(metadata)
    }

    func fetchSharedDatabaseRecords() async throws -> [CKRecord] {
        let sharedDatabase = container.sharedCloudDatabase
        let zones = try await sharedDatabase.allRecordZones()
        var allRecords: [CKRecord] = []

        for zone in zones {
            let query = CKQuery(recordType: "Transaction", predicate: NSPredicate(value: true))
            let (matchResults, _) = try await sharedDatabase.records(matching: query)
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    allRecords.append(record)
                case .failure:
                    continue
                }
            }
        }

        return allRecords
    }
}
