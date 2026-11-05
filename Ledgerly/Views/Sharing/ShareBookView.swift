import SwiftUI
import CloudKit

struct ShareBookView: View {
    let book: Book
    @EnvironmentObject var loc: LocalizationManager
    @StateObject private var sharingVM = SharingViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var showSharingController = false
    @State private var share: CKShare?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "person.2.circle")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.accentColor)

                Text(String(format: loc["share.shareName"], book.displayName))
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(loc["share.subtitle"])
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 12) {
                    ShareFeatureRow(icon: "link", title: loc["share.inviteViaLink"], description: loc["share.inviteViaLinkDesc"])
                    ShareFeatureRow(icon: "person.badge.plus", title: loc["share.permissions"], description: loc["share.permissionsDesc"])
                    ShareFeatureRow(icon: "arrow.triangle.2.circlepath", title: loc["share.realtimeSync"], description: loc["share.realtimeSyncDesc"])
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer()

                Button {
                    initiateSharing()
                } label: {
                    HStack {
                        if sharingVM.isSharing {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(sharingVM.isSharing ? loc["share.creating"] : loc["share.startSharing"])
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(sharingVM.isSharing)

                if let error = sharingVM.shareError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding()
            .navigationTitle(loc["share.title"])
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(loc["share.cancel"]) { dismiss() }
                }
            }
        }
    }

    private func initiateSharing() {
        Task {
            if let share = await createShareForBook() {
                self.share = share
                showSharingController = true
            }
        }
    }

    private func createShareForBook() async -> CKShare? {
        let container = CKContainer(identifier: "iCloud.com.ledgerly.app")
        let zoneId = CKRecordZone.ID(
            zoneName: "BookZone_\(book.id.uuidString)",
            ownerName: CKCurrentUserDefaultName
        )

        do {
            let zone = CKRecordZone(zoneID: zoneId)
            try await container.privateCloudDatabase.save(zone)

            let recordId = CKRecord.ID(recordName: book.id.uuidString, zoneID: zoneId)
            let rootRecord = CKRecord(recordType: "Book", recordID: recordId)
            rootRecord["name"] = book.name as CKRecordValue
            rootRecord["icon"] = book.icon as CKRecordValue
            try await container.privateCloudDatabase.save(rootRecord)

            let share = CKShare(recordZoneID: zoneId)
            share[CKShare.SystemFieldKey.title] = "\(book.name)" as CKRecordValue
            share[CKShare.SystemFieldKey.shareType] = "com.bookkeeper.shared-book" as CKRecordValue
            share.publicPermission = .readOnly

            try await container.privateCloudDatabase.modifyRecords(saving: [rootRecord, share], deleting: [])
            return share
        } catch {
            sharingVM.shareError = error.localizedDescription
            return nil
        }
    }
}

struct ShareFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

