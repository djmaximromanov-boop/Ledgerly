import SwiftUI
import CoreData

struct CategorySortView: View {
    let book: Book
    let categoryType: CategoryType

    @Environment(\.dismiss) private var dismiss
    @State private var categories: [Category] = []

    var body: some View {
        NavigationStack {
            List {
                ForEach(categories, id: \.id) { category in
                    HStack(spacing: 12) {
                        Image(systemName: category.icon)
                            .font(.title3)
                            .frame(width: 40, height: 40)
                            .background(Color.accentColor.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        Text(category.name)
                            .font(.body)

                        Spacer()

                        if category.isSystem {
                            Text("Default")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color(.systemGray5))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onMove(perform: move)
            }
            .navigationTitle("Sort Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
            .onAppear {
                loadCategories()
            }
        }
    }

    private func loadCategories() {
        let allCategories = book.categories?.allObjects as? [Category] ?? []
        categories = allCategories
            .filter { $0.categoryType == categoryType && $0.isTopLevel }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    private func move(from source: IndexSet, to destination: Int) {
        categories.move(fromOffsets: source, toOffset: destination)

        for (index, category) in categories.enumerated() {
            category.sortOrder = Int32(index)
        }

        try? PersistenceController.shared.save()
    }
}
