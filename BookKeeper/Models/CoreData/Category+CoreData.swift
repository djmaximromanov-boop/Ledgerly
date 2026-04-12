import Foundation
import CoreData

@objc(Category)
public class Category: NSManagedObject, Identifiable {
}

extension Category {
    @NSManaged public var icon: String
    @NSManaged public var id: UUID
    @NSManaged public var isSystem: Bool
    @NSManaged public var name: String
    @NSManaged public var parentId: UUID?
    @NSManaged public var sortOrder: Int32
    @NSManaged public var type: String
    @NSManaged public var book: Book?
    @NSManaged public var transactions: NSSet?

    var categoryType: CategoryType {
        get { CategoryType(rawValue: type) ?? .expense }
        set { type = newValue.rawValue }
    }

    var isTopLevel: Bool {
        parentId == nil
    }

    var canDelete: Bool {
        !isSystem
    }

    static let defaultExpenseCategories: [(name: String, icon: String, children: [(String, String)])] = [
        ("Food", "fork.knife", [
            ("Breakfast", "cup.and.saucer.fill"),
            ("Lunch", "takeoutbag.and.cup.and.straw.fill"),
            ("Dinner", "wineglass.fill"),
            ("Snacks", "birthday.cake.fill"),
            ("Drinks", "mug.fill"),
            ("Fruits", "apple.fill"),
            ("Takeout", "bag.fill")
        ]),
        ("Transport", "car.fill", [
            ("Bus", "bus.fill"),
            ("Metro", "tram.fill"),
            ("Taxi", "car.side.fill"),
            ("Gas", "fuelpump.fill"),
            ("Parking", "parkingsign.circle.fill"),
            ("Toll", "building.columns.fill"),
            ("Bike Share", "bicycle")
        ]),
        ("Shopping", "bag.fill", [
            ("Clothes", "shirt.fill"),
            ("Daily Goods", "house.fill"),
            ("Electronics", "laptopcomputer.and.iphone"),
            ("Cosmetics", "drop.fill"),
            ("Shoes & Bags", "handbag.fill"),
            ("Appliances", "tv.fill")
        ]),
        ("Housing", "house.fill", [
            ("Rent", "building.fill"),
            ("Utilities", "bolt.fill"),
            ("HOA", "building.2.fill"),
            ("Repairs", "wrench.and.screwdriver.fill"),
            ("Gas Bill", "flame.fill"),
            ("Internet", "wifi")
        ]),
        ("Entertainment", "gamecontroller.fill", [
            ("Movies", "film.fill"),
            ("Games", "gamecontroller.fill"),
            ("Travel", "airplane.departure"),
            ("Sports", "figure.run"),
            ("Music", "music.note"),
            ("Social", "person.2.fill")
        ]),
        ("Healthcare", "stethoscope", [
            ("Clinic", "stethoscope"),
            ("Medicine", "pills.fill"),
            ("Checkup", "heart.text.square.fill"),
            ("Dental", "mouth.fill"),
            ("Wellness", "heart.circle.fill")
        ]),
        ("Education", "book.fill", [
            ("Training", "graduationcap.fill"),
            ("Books", "book.fill"),
            ("Courses", "character.book.fill"),
            ("Exams", "doc.text.fill"),
            ("Stationery", "pencil")
        ]),
        ("Telecom", "phone.fill", [
            ("Phone Bill", "phone.fill"),
            ("Internet", "wifi"),
            ("Membership", "person.crop.circle.fill"),
            ("Delivery", "shippingbox.fill")
        ]),
        ("Social Gifts", "gift.fill", [
            ("Red Envelope", "gift.fill"),
            ("Cash Gift", "banknote.fill"),
            ("Hosting", "wineglass.fill"),
            ("Gifts", "heart.fill")
        ]),
        ("Pets", "pawprint.fill", [
            ("Cat Food", "pawprint.fill"),
            ("Dog Food", "pawprint.fill"),
            ("Pet Healthcare", "stethoscope"),
            ("Pet Supplies", "bag.fill")
        ]),
    ]

    static let defaultIncomeCategories: [(name: String, icon: String, children: [(String, String)])] = [
        ("Salary", "banknote.fill", [
            ("Monthly", "banknote.fill"),
            ("Bonus", "gift.fill"),
            ("Overtime", "clock.fill"),
            ("Year-end Bonus", "star.fill")
        ]),
        ("Investment", "chart.line.uptrend.xyaxis", [
            ("Stocks", "chart.line.uptrend.xyaxis"),
            ("Funds", "chart.bar.fill"),
            ("Interest", "percent"),
            ("Wealth Mgmt", "coins")
        ]),
        ("Side Job", "briefcase.fill", [
            ("Freelance", "laptopcomputer.and.iphone"),
            ("Consulting", "person.wave.2.fill"),
            ("Royalties", "pencil.line")
        ]),
        ("Other Income", "plus.circle.fill", [
            ("Red Envelope", "gift.fill"),
            ("Refund", "arrow.uturn.backward.circle.fill"),
            ("Reimbursement", "doc.text.fill"),
            ("Lottery", "star.circle.fill")
        ]),
    ]

    static func createDefaultCategories(for book: Book, in context: NSManagedObjectContext) {
        var sortOrder: Int32 = 0

        for parent in defaultExpenseCategories {
            let parentCategory = Category(context: context)
            parentCategory.id = UUID()
            parentCategory.name = parent.name
            parentCategory.icon = parent.icon
            parentCategory.categoryType = .expense
            parentCategory.sortOrder = sortOrder
            parentCategory.isSystem = true
            parentCategory.book = book
            sortOrder += 1

            for child in parent.children {
                let childCategory = Category(context: context)
                childCategory.id = UUID()
                childCategory.name = child.0
                childCategory.icon = child.1
                childCategory.categoryType = .expense
                childCategory.parentId = parentCategory.id
                childCategory.sortOrder = sortOrder
                childCategory.isSystem = true
                childCategory.book = book
                sortOrder += 1
            }
        }

        for parent in defaultIncomeCategories {
            let parentCategory = Category(context: context)
            parentCategory.id = UUID()
            parentCategory.name = parent.name
            parentCategory.icon = parent.icon
            parentCategory.categoryType = .income
            parentCategory.sortOrder = sortOrder
            parentCategory.isSystem = true
            parentCategory.book = book
            sortOrder += 1

            for child in parent.children {
                let childCategory = Category(context: context)
                childCategory.id = UUID()
                childCategory.name = child.0
                childCategory.icon = child.1
                childCategory.categoryType = .income
                childCategory.parentId = parentCategory.id
                childCategory.sortOrder = sortOrder
                childCategory.isSystem = true
                childCategory.book = book
                sortOrder += 1
            }
        }
    }

    static func create(
        in context: NSManagedObjectContext,
        name: String,
        icon: String,
        categoryType: CategoryType,
        book: Book,
        parentId: UUID? = nil,
        sortOrder: Int32 = 0
    ) -> Category {
        let category = Category(context: context)
        category.id = UUID()
        category.name = name
        category.icon = icon
        category.categoryType = categoryType
        category.sortOrder = sortOrder
        category.isSystem = false
        category.parentId = parentId
        category.book = book
        return category
    }
}
