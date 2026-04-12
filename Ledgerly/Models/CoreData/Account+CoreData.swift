import Foundation
import CoreData

@objc(Account)
public class Account: NSManagedObject {
}

extension Account {
    @NSManaged public var balance: NSDecimalNumber
    @NSManaged public var icon: String
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var type: String
    @NSManaged public var book: Book?

    var accountType: AccountType {
        get { AccountType(rawValue: type) ?? .cash }
        set { type = newValue.rawValue }
    }

    static func create(
        in context: NSManagedObjectContext,
        name: String,
        book: Book,
        type: AccountType = .cash,
        balance: Decimal = 0,
        icon: String = "wallet"
    ) -> Account {
        let account = Account(context: context)
        account.id = UUID()
        account.name = name
        account.accountType = type
        account.balance = NSDecimalNumber(decimal: balance)
        account.icon = icon
        account.book = book
        return account
    }
}
