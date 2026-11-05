import Foundation
import CloudKit

actor ArchiveService {
    static let shared = ArchiveService()

    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let archiveThresholdMonths: Int = 6
    private let recordCountThreshold: Int = 10_000

    private init() {
        container = CKContainer(identifier: "iCloud.com.ledgerly.app")
        privateDatabase = container.privateCloudDatabase
    }

    func checkAndArchiveIfNeeded(bookId: UUID) async throws {
        let zoneId = CKRecordZone.ID(
            zoneName: "BookZone_\(bookId.uuidString)",
            ownerName: CKCurrentUserDefaultName
        )

        let query = CKQuery(recordType: "Transaction", predicate: NSPredicate(value: true))
        let (matchResults, _) = try await privateDatabase.records(matching: query, resultsLimit: 1)

        let totalCount = matchResults.count
        guard totalCount > recordCountThreshold else { return }

        try await archiveOldRecords(bookId: bookId, zoneId: zoneId)
    }

    private func archiveOldRecords(bookId: UUID, zoneId: CKRecordZone.ID) async throws {
        let cutoffDate = Calendar.current.date(byAdding: .month, value: -archiveThresholdMonths, to: Date())!

        let predicate = NSPredicate(format: "date < %@", cutoffDate as NSDate)
        let query = CKQuery(recordType: "Transaction", predicate: predicate)

        let archiveZoneId = CKRecordZone.ID(
            zoneName: "ArchiveZone_\(bookId.uuidString)",
            ownerName: CKCurrentUserDefaultName
        )

        let archiveZone = CKRecordZone(zoneID: archiveZoneId)
        try await privateDatabase.save(archiveZone)

        var cursor: CKQueryOperation.Cursor?
        var hasMore = true

        while hasMore {
            let (matchResults, nextCursor) = try await privateDatabase.records(matching: query)

            var recordsToDelete: [CKRecord.ID] = []
            var recordsToSave: [CKRecord] = []

            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    let archiveRecordId = CKRecord.ID(recordName: record.recordID.recordName, zoneID: archiveZoneId)
                    let archiveRecord = CKRecord(recordType: "ArchivedTransaction", recordID: archiveRecordId)
                    for key in record.allKeys() {
                        archiveRecord[key] = record[key]
                    }
                    recordsToSave.append(archiveRecord)
                    recordsToDelete.append(record.recordID)

                case .failure:
                    continue
                }
            }

            if !recordsToSave.isEmpty {
                try await privateDatabase.modifyRecords(saving: recordsToSave, deleting: recordsToDelete)
            }

            cursor = nextCursor
            hasMore = cursor != nil
        }

        try await createMonthlySummary(bookId: bookId, zoneId: zoneId, cutoffDate: cutoffDate)
    }

    private func createMonthlySummary(bookId: UUID, zoneId: CKRecordZone.ID, cutoffDate: Date) async throws {
        let summaryRecordId = CKRecord.ID(
            recordName: "Summary_\(bookId.uuidString)_\(Int(cutoffDate.timeIntervalSince1970))",
            zoneID: zoneId
        )
        let summary = CKRecord(recordType: "MonthlySummary", recordID: summaryRecordId)
        summary["bookId"] = bookId.uuidString as CKRecordValue
        summary["archivedDate"] = Date() as CKRecordValue
        summary["cutoffDate"] = cutoffDate as CKRecordValue
        try await privateDatabase.save(summary)
    }
}
