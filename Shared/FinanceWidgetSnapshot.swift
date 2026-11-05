import Foundation

struct FinanceWidgetSnapshot: Codable {
    let bookName: String
    let currencyCode: String
    let expensesThisMonth: Decimal
    let incomeThisMonth: Decimal
    let totalAccountBalance: Decimal
    let hasBook: Bool
    let updatedAt: Date

    static let empty = FinanceWidgetSnapshot(
        bookName: "MORE Finance",
        currencyCode: "RUB",
        expensesThisMonth: 0,
        incomeThisMonth: 0,
        totalAccountBalance: 0,
        hasBook: false,
        updatedAt: .now
    )
}

enum FinanceWidgetSnapshotStore {
    static let appGroupIdentifier = "group.com.ledgerly.app"
    static let snapshotKey = "financeWidgetSnapshot"
    static let widgetKind = "LedgerlyFinanceWidget"

    static func load() -> FinanceWidgetSnapshot {
        guard
            let data = UserDefaults(suiteName: appGroupIdentifier)?.data(forKey: snapshotKey),
            let snapshot = try? JSONDecoder().decode(FinanceWidgetSnapshot.self, from: data)
        else {
            return .empty
        }
        return snapshot
    }

    static func save(_ snapshot: FinanceWidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults(suiteName: appGroupIdentifier)?.set(data, forKey: snapshotKey)
    }
}
