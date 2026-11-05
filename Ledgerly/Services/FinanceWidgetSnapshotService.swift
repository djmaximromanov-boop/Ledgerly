import CoreData
import WidgetKit

@MainActor
enum FinanceWidgetSnapshotService {
    static func refresh(book: Book?, context: NSManagedObjectContext) {
        guard let book else {
            FinanceWidgetSnapshotStore.save(.empty)
            WidgetCenter.shared.reloadTimelines(ofKind: FinanceWidgetSnapshotStore.widgetKind)
            return
        }

        let now = Date()
        let month = Calendar.current.dateInterval(of: .month, for: now)
        let transactions: [Transaction]

        if let month {
            let request = NSFetchRequest<Transaction>(entityName: "Transaction")
            request.predicate = NSPredicate(
                format: "book == %@ AND date >= %@ AND date < %@",
                book,
                month.start as NSDate,
                month.end as NSDate
            )
            transactions = (try? context.fetch(request)) ?? []
        } else {
            transactions = []
        }

        let expenses = transactions
            .filter { $0.transactionType == .expense }
            .reduce(Decimal.zero) { $0 + $1.amount.decimalValue }
        let income = transactions
            .filter { $0.transactionType == .income }
            .reduce(Decimal.zero) { $0 + $1.amount.decimalValue }
        let accountBalance = (book.accounts?.allObjects as? [Account] ?? [])
            .reduce(Decimal.zero) { $0 + $1.balance.decimalValue }

        let snapshot = FinanceWidgetSnapshot(
            bookName: book.displayName,
            currencyCode: book.currency,
            expensesThisMonth: expenses,
            incomeThisMonth: income,
            totalAccountBalance: accountBalance,
            hasBook: true,
            updatedAt: now
        )
        FinanceWidgetSnapshotStore.save(snapshot)
        WidgetCenter.shared.reloadTimelines(ofKind: FinanceWidgetSnapshotStore.widgetKind)
    }
}
