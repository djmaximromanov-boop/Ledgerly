import Foundation
import CoreData

@objc(Book)
public class Book: NSManagedObject {
}

extension Book {
    @NSManaged public var createdAt: Date
    @NSManaged public var currency: String
    @NSManaged public var icon: String
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var type: String
    @NSManaged public var categories: NSSet?
    @NSManaged public var members: NSSet?
    @NSManaged public var transactions: NSSet?
    @NSManaged public var budgets: NSSet?
    @NSManaged public var accounts: NSSet?

    var bookType: BookType {
        get { BookType(rawValue: type) ?? .personal }
        set { type = newValue.rawValue }
    }

    var totalExpense: Decimal {
        (transactions?.allObjects as? [Transaction] ?? [])
            .filter { $0.transactionType == .expense }
            .reduce(Decimal(0)) { $0 + ($1.amount as Decimal) }
    }

    var totalIncome: Decimal {
        (transactions?.allObjects as? [Transaction] ?? [])
            .filter { $0.transactionType == .income }
            .reduce(Decimal(0)) { $0 + ($1.amount as Decimal) }
    }

    var balance: Decimal {
        totalIncome - totalExpense
    }

    static func create(
        in context: NSManagedObjectContext,
        name: String,
        icon: String = "book",
        type: BookType = .personal,
        currency: String = "CNY"
    ) -> Book {
        let book = Book(context: context)
        book.id = UUID()
        book.name = name
        book.icon = icon
        book.bookType = type
        book.currency = currency
        book.createdAt = Date()
        return book
    }
}
