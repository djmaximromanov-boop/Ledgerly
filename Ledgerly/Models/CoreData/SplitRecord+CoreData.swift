import Foundation
import CoreData

@objc(SplitRecord)
public class SplitRecord: NSManagedObject {
}

extension SplitRecord {
    @NSManaged public var id: UUID
    @NSManaged public var shareAmount: NSDecimalNumber
    @NSManaged public var shareRatio: Double
    @NSManaged public var member: Member?
    @NSManaged public var transaction: Transaction?

    static func create(
        in context: NSManagedObjectContext,
        transaction: Transaction,
        member: Member,
        shareAmount: Decimal,
        shareRatio: Double
    ) -> SplitRecord {
        let record = SplitRecord(context: context)
        record.id = UUID()
        record.shareAmount = NSDecimalNumber(decimal: shareAmount)
        record.shareRatio = shareRatio
        record.transaction = transaction
        record.member = member
        return record
    }
}
