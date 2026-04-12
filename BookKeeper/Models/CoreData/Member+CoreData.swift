import Foundation
import CoreData

@objc(Member)
public class Member: NSManagedObject {
}

extension Member {
    @NSManaged public var id: UUID
    @NSManaged public var joinedAt: Date
    @NSManaged public var name: String
    @NSManaged public var role: String
    @NSManaged public var userId: String?
    @NSManaged public var book: Book?
    @NSManaged public var transactions: NSSet?
    @NSManaged public var splitRecords: NSSet?

    var memberRole: MemberRole {
        get { MemberRole(rawValue: role) ?? .editor }
        set { role = newValue.rawValue }
    }

    static func create(
        in context: NSManagedObjectContext,
        name: String,
        book: Book,
        role: MemberRole = .owner,
        userId: String? = nil
    ) -> Member {
        let member = Member(context: context)
        member.id = UUID()
        member.name = name
        member.memberRole = role
        member.userId = userId
        member.joinedAt = Date()
        member.book = book
        return member
    }
}
