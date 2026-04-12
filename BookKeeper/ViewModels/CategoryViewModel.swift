import Foundation
import CoreData

@MainActor
class CategoryViewModel: ObservableObject {
    @Published var errorMessage: String? = nil

    func addCategory(
        name: String,
        icon: String,
        type: CategoryType,
        to book: Book,
        parent: Category? = nil
    ) -> Bool {
        guard !name.isEmpty else {
            errorMessage = "Please enter a category name"
            return false
        }

        let context = PersistenceController.shared.viewContext

        let categories = book.categories?.allObjects as? [Category] ?? []
        let maxSortOrder = categories.map { $0.sortOrder }.max() ?? 0

        let _ = Category.create(
            in: context,
            name: name,
            icon: icon,
            categoryType: type,
            book: book,
            parentId: parent?.id,
            sortOrder: maxSortOrder + 1
        )

        do {
            try context.save()
            errorMessage = nil
            return true
        } catch {
            errorMessage = "Save failed: \(error.localizedDescription)"
            return false
        }
    }

    func updateCategory(
        _ category: Category,
        name: String,
        icon: String
    ) -> Bool {
        guard !name.isEmpty else {
            errorMessage = "Please enter a category name"
            return false
        }

        category.name = name
        category.icon = icon

        do {
            try PersistenceController.shared.save()
            errorMessage = nil
            return true
        } catch {
            errorMessage = "Save failed: \(error.localizedDescription)"
            return false
        }
    }

    func deleteCategory(_ category: Category) -> Bool {
        guard category.canDelete else {
            errorMessage = "Default categories cannot be deleted"
            return false
        }

        if let transactionCount = category.transactions?.count, transactionCount > 0 {
            errorMessage = "This category has \(transactionCount) records and cannot be deleted"
            return false
        }

        PersistenceController.shared.delete(category)
        errorMessage = nil
        return true
    }

    func getCategories(for book: Book, type: CategoryType) -> [Category] {
        let categories = book.categories?.allObjects as? [Category] ?? []
        return categories
            .filter { $0.categoryType == type && $0.isTopLevel }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    func getSubCategories(for parent: Category) -> [Category] {
        guard let book = parent.book else { return [] }
        let categories = book.categories?.allObjects as? [Category] ?? []
        return categories
            .filter { $0.parentId == parent.id }
            .sorted { $0.sortOrder < $1.sortOrder }
    }
}
