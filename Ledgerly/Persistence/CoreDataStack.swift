import CoreData

class CoreDataStack {
    static let shared = CoreDataStack()

    private let persistenceController: PersistenceController

    var viewContext: NSManagedObjectContext {
        persistenceController.viewContext
    }

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistenceController.container.performBackgroundTask { context in
            block(context)
            if context.hasChanges {
                try? context.save()
            }
        }
    }

    func fetch<T: NSManagedObject>(
        _ type: T.Type,
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil
    ) -> [T] {
        let request = T.fetchRequest() as! NSFetchRequest<T>
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        return (try? viewContext.fetch(request)) ?? []
    }

    func count<T: NSManagedObject>(
        _ type: T.Type,
        predicate: NSPredicate? = nil
    ) -> Int {
        let request = T.fetchRequest() as! NSFetchRequest<T>
        request.predicate = predicate
        return (try? viewContext.count(for: request)) ?? 0
    }
}
