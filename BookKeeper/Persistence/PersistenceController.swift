import CoreData

class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentCloudKitContainer
    let inMemory: Bool

    init(inMemory: Bool = false) {
        self.inMemory = inMemory
        container = NSPersistentCloudKitContainer(name: "BookKeeper")

        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to load persistent store description")
        }

        if inMemory {
            description.url = URL(fileURLWithPath: "/dev/null")
        } else {
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

            #if targetEnvironment(simulator)
            description.cloudKitContainerOptions = nil
            #else
            let options = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.com.bookkeeper.app"
            )
            description.cloudKitContainerOptions = options
            #endif
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                print("Core Data load error: \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }

    func save() {
        guard viewContext.hasChanges else { return }
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Core Data save error: \(nsError), \(nsError.userInfo)")
        }
    }

    func delete(_ object: NSManagedObject) {
        viewContext.delete(object)
        save()
    }

    func hasBooks() -> Bool {
        let request = NSFetchRequest<Book>(entityName: "Book")
        request.fetchLimit = 1
        return (try? viewContext.count(for: request)) ?? 0 > 0
    }

    func seedDemoDataIfNeeded() {
        guard !hasBooks() else { return }

        let context = viewContext

        let personalBook = Book.create(in: context, name: LocalizationManager.localized("demo.dailyExpenses"), icon: "house", type: .personal)
        Category.createDefaultCategories(for: personalBook, in: context)
        let owner1 = Member.create(in: context, name: LocalizationManager.localized("demo.me"), book: personalBook, role: .owner)

        let sharedBook = Book.create(in: context, name: LocalizationManager.localized("demo.familyLedger"), icon: "house.fill", type: .shared)
        Category.createDefaultCategories(for: sharedBook, in: context)
        let owner2 = Member.create(in: context, name: LocalizationManager.localized("demo.me"), book: sharedBook, role: .owner)
        let spouse = Member.create(in: context, name: LocalizationManager.localized("demo.partner"), book: sharedBook, role: .editor)
        let _ = Member.create(in: context, name: LocalizationManager.localized("demo.mom"), book: sharedBook, role: .viewer)

        let personalCategories = (personalBook.categories?.allObjects as? [Category] ?? [])
            .filter { $0.isTopLevel && $0.categoryType == .expense }
        let sharedCategories = (sharedBook.categories?.allObjects as? [Category] ?? [])
            .filter { $0.isTopLevel && $0.categoryType == .expense }
        let personalIncomeCategories = (personalBook.categories?.allObjects as? [Category] ?? [])
            .filter { $0.isTopLevel && $0.categoryType == .income }
        let sharedIncomeCategories = (sharedBook.categories?.allObjects as? [Category] ?? [])
            .filter { $0.isTopLevel && $0.categoryType == .income }

        let calendar = Calendar.current
        let today = Date()

        for dayOffset in 0..<90 {
            let date = today.adding(days: -dayOffset)
            let dayOfMonth = calendar.component(.day, from: date)

            if let cat = personalCategories[safe: 0] {
                let _ = Transaction.create(
                    in: context, amount: Decimal(Int.random(in: 15...40)),
                    type: .expense, category: cat, book: personalBook,
                    member: owner1, note: LocalizationManager.localized("demo.breakfast"), date: date
                )
                let _ = Transaction.create(
                    in: context, amount: Decimal(Int.random(in: 30...60)),
                    type: .expense, category: cat, book: personalBook,
                    member: owner1, note: LocalizationManager.localized("demo.lunch"), date: date
                )
                let _ = Transaction.create(
                    in: context, amount: Decimal(Int.random(in: 40...100)),
                    type: .expense, category: cat, book: personalBook,
                    member: owner1, note: LocalizationManager.localized("demo.dinner"), date: date
                )
            }

            if dayOffset % 7 < 2, let cat = personalCategories[safe: 1] {
                let notes = [LocalizationManager.localized("demo.bus"), LocalizationManager.localized("demo.metro"), LocalizationManager.localized("demo.taxi")]
                let _ = Transaction.create(
                    in: context, amount: Decimal(Int.random(in: 5...50)),
                    type: .expense, category: cat, book: personalBook,
                    member: owner1, note: notes.randomElement()!, date: date
                )
            }

            if Int.random(in: 0...6) < 2, let cat = personalCategories[safe: 2] {
                let notes = [LocalizationManager.localized("demo.grocery"), LocalizationManager.localized("demo.dailyNecessities"), LocalizationManager.localized("demo.clothes")]
                let _ = Transaction.create(
                    in: context, amount: Decimal(Int.random(in: 30...300)),
                    type: .expense, category: cat, book: personalBook,
                    member: owner1, note: notes.randomElement()!, date: date
                )
            }

            if Int.random(in: 0...13) < 2, let cat = personalCategories[safe: 4] {
                let notes = [LocalizationManager.localized("demo.movie"), LocalizationManager.localized("demo.game"), LocalizationManager.localized("demo.party")]
                let _ = Transaction.create(
                    in: context, amount: Decimal(Int.random(in: 30...200)),
                    type: .expense, category: cat, book: personalBook,
                    member: owner1, note: notes.randomElement()!, date: date
                )
            }

            if dayOfMonth == 1, let cat = personalCategories[safe: 3] {
                let _ = Transaction.create(
                    in: context, amount: 3200,
                    type: .expense, category: cat, book: personalBook,
                    member: owner1, note: LocalizationManager.localized("demo.rent"), date: date
                )
                let _ = Transaction.create(
                    in: context, amount: Decimal(Int.random(in: 80...200)),
                    type: .expense, category: cat, book: personalBook,
                    member: owner1, note: LocalizationManager.localized("demo.utilities"), date: date
                )
            }

            if dayOfMonth == 15, let cat = personalCategories[safe: 7] {
                let _ = Transaction.create(
                    in: context, amount: 128,
                    type: .expense, category: cat, book: personalBook,
                    member: owner1, note: LocalizationManager.localized("demo.phoneBill"), date: date
                )
            }

            if dayOfMonth == 5, let cat = personalIncomeCategories.first {
                let _ = Transaction.create(
                    in: context, amount: 12000,
                    type: .income, category: cat, book: personalBook,
                    member: owner1, note: LocalizationManager.localized("demo.salary"), date: date
                )
            }
        }

        for dayOffset in 0..<90 {
            let date = today.adding(days: -dayOffset)
            let dayOfMonth = calendar.component(.day, from: date)

            if let cat = sharedCategories[safe: 0] {
                let _ = Transaction.create(
                    in: context, amount: Decimal(Int.random(in: 15...40)),
                    type: .expense, category: cat, book: sharedBook,
                    member: owner2, note: LocalizationManager.localized("demo.breakfast"), date: date
                )
                let _ = Transaction.create(
                    in: context, amount: Decimal(Int.random(in: 30...60)),
                    type: .expense, category: cat, book: sharedBook,
                    member: owner2, note: LocalizationManager.localized("demo.lunch"), date: date
                )
                let _ = Transaction.create(
                    in: context, amount: Decimal(Int.random(in: 50...120)),
                    type: .expense, category: cat, book: sharedBook,
                    member: owner2, note: LocalizationManager.localized("demo.familyDinner"), date: date
                )
            }

            if Int.random(in: 0...2) < 2, let cat = sharedCategories[safe: 0] {
                let _ = Transaction.create(
                    in: context, amount: Decimal(Int.random(in: 15...40)),
                    type: .expense, category: cat, book: sharedBook,
                    member: spouse, note: LocalizationManager.localized("demo.breakfast"), date: date
                )
            }

            if Int.random(in: 0...2) < 2, let cat = sharedCategories[safe: 0] {
                let _ = Transaction.create(
                    in: context, amount: Decimal(Int.random(in: 30...60)),
                    type: .expense, category: cat, book: sharedBook,
                    member: spouse, note: LocalizationManager.localized("demo.lunch"), date: date
                )
            }

            if dayOffset % 7 < 2, let cat = sharedCategories[safe: 1] {
                let notes = [LocalizationManager.localized("demo.bus"), LocalizationManager.localized("demo.metro"), LocalizationManager.localized("demo.taxi"), LocalizationManager.localized("demo.gas")]
                let member = Int.random(in: 0...1) == 0 ? owner2 : spouse
                let _ = Transaction.create(
                    in: context, amount: Decimal(Int.random(in: 5...60)),
                    type: .expense, category: cat, book: sharedBook,
                    member: member, note: notes.randomElement()!, date: date
                )
            }

            if Int.random(in: 0...6) < 2, let cat = sharedCategories[safe: 2] {
                let notes = [LocalizationManager.localized("demo.groceryShopping"), LocalizationManager.localized("demo.dailyNecessities"), LocalizationManager.localized("demo.householdItems")]
                let member = Int.random(in: 0...1) == 0 ? owner2 : spouse
                let _ = Transaction.create(
                    in: context, amount: Decimal(Int.random(in: 50...400)),
                    type: .expense, category: cat, book: sharedBook,
                    member: member, note: notes.randomElement()!, date: date
                )
            }

            if dayOfMonth == 1, let cat = sharedCategories[safe: 3] {
                let _ = Transaction.create(
                    in: context, amount: 4500,
                    type: .expense, category: cat, book: sharedBook,
                    member: owner2, note: LocalizationManager.localized("demo.rent"), date: date
                )
                let _ = Transaction.create(
                    in: context, amount: Decimal(Int.random(in: 100...300)),
                    type: .expense, category: cat, book: sharedBook,
                    member: owner2, note: LocalizationManager.localized("demo.utilityBills"), date: date
                )
            }

            if dayOfMonth == 5, let cat = sharedIncomeCategories.first {
                let _ = Transaction.create(
                    in: context, amount: 15000,
                    type: .income, category: cat, book: sharedBook,
                    member: owner2, note: LocalizationManager.localized("demo.salary"), date: date
                )
                let _ = Transaction.create(
                    in: context, amount: 12000,
                    type: .income, category: cat, book: sharedBook,
                    member: spouse, note: LocalizationManager.localized("demo.salary"), date: date
                )
            }
        }

        let _ = Budget.create(in: context, book: personalBook, amount: 5000, period: .monthly)
        let _ = Budget.create(in: context, book: sharedBook, amount: 15000, period: .monthly)

        save()
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
