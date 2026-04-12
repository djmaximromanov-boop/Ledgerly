import Foundation
import CoreData

@objc(Transaction)
public class Transaction: NSManagedObject {
}

extension Transaction {
    @NSManaged public var amount: NSDecimalNumber
    @NSManaged public var createdAt: Date
    @NSManaged public var date: Date
    @NSManaged public var id: UUID
    @NSManaged public var note: String?
    @NSManaged public var tagsData: Data?
    @NSManaged public var type: String
    @NSManaged public var updatedAt: Date
    @NSManaged public var book: Book?
    @NSManaged public var category: Category?
    @NSManaged public var member: Member?
    @NSManaged public var splitRecords: NSSet?

    var transactionType: TransactionType {
        get { TransactionType(rawValue: type) ?? .expense }
        set { type = newValue.rawValue }
    }

    var tagsList: [String] {
        get {
            guard let data = tagsData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            tagsData = try? JSONEncoder().encode(newValue)
        }
    }

    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CNY"
        return formatter.string(from: amount) ?? "¥0.00"
    }

    static func create(
        in context: NSManagedObjectContext,
        amount: Decimal,
        type: TransactionType,
        category: Category,
        book: Book,
        member: Member? = nil,
        note: String? = nil,
        tags: [String] = [],
        date: Date = Date()
    ) -> Transaction {
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.amount = NSDecimalNumber(decimal: amount)
        transaction.transactionType = type
        transaction.note = note
        transaction.tagsList = tags
        transaction.date = date
        transaction.createdAt = Date()
        transaction.updatedAt = Date()
        transaction.category = category
        transaction.book = book
        transaction.member = member
        return transaction
    }
}
