import SwiftUI
import CoreData

struct CategoryListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var bookVM: BookViewModel
    @StateObject private var categoryVM = CategoryViewModel()

    @State private var selectedType: CategoryType = .expense
    @State private var showAddSheet = false
    @State private var showSortSheet = false
    @State private var editingCategory: Category? = nil
    @State private var newCategoryName = ""
    @State private var newCategoryIcon = "fork.knife"
    @FocusState private var isEditNameFocused: Bool

    let iconOptions = [
        "fork.knife", "cup.and.saucer.fill", "takeoutbag.and.cup.and.straw.fill",
        "wineglass.fill", "birthday.cake.fill", "mug.fill", "apple.fill", "bag.fill",
        "car.fill", "bus.fill", "tram.fill", "car.side.fill", "fuelpump.fill",
        "parkingsign.circle.fill", "bicycle", "airplane.departure",
        "bag.fill", "shirt.fill", "house.fill", "laptopcomputer.and.iphone",
        "drop.fill", "handbag.fill", "tv.fill",
        "house.fill", "building.fill", "bolt.fill", "building.2.fill",
        "wrench.and.screwdriver.fill", "flame.fill", "wifi",
        "gamecontroller.fill", "film.fill", "figure.run", "music.note",
        "person.2.fill", "dice.fill", "ticket.fill",
        "stethoscope", "pills.fill", "heart.text.square.fill",
        "mouth.fill", "heart.circle.fill",
        "book.fill", "graduationcap.fill", "character.book.fill",
        "doc.text.fill", "pencil",
        "phone.fill", "shippingbox.fill", "person.crop.circle.fill",
        "gift.fill", "banknote.fill", "heart.fill",
        "pawprint.fill",
        "chart.line.uptrend.xyaxis", "chart.bar.fill", "percent", "coins",
        "briefcase.fill", "person.wave.2.fill", "pencil.line",
        "star.fill", "star.circle.fill", "arrow.uturn.backward.circle.fill",
        "lightbulb.fill", "leaf.fill", "tag.fill", "cart.fill",
        "creditcard.fill", "wallet.pass.fill", "calendar", "clock.fill"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerSection

                if let book = bookVM.currentBook {
                    let categories = categoryVM.getCategories(for: book, type: selectedType)

                    if categories.isEmpty {
                        emptyState
                    } else {
                        List {
                            ForEach(categories, id: \.id) { category in
                                categoryRow(category: category)
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if let book = bookVM.currentBook {
                        Button {
                            showSortSheet = true
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editingCategory = nil
                        newCategoryName = ""
                        newCategoryIcon = "fork.knife"
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                categoryEditSheet()
            }
            .sheet(isPresented: $showSortSheet) {
                if let book = bookVM.currentBook {
                    CategorySortView(book: book, categoryType: selectedType)
                }
            }
            .alert("Error", isPresented: .constant(categoryVM.errorMessage != nil)) {
                Button("OK") { categoryVM.errorMessage = nil }
            } message: {
                Text(categoryVM.errorMessage ?? "")
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 0) {
            Picker("Type", selection: $selectedType) {
                Text("Expense").tag(CategoryType.expense)
                Text("Income").tag(CategoryType.income)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 12)

            if let book = bookVM.currentBook {
                let categories = categoryVM.getCategories(for: book, type: selectedType)
                let topLevel = categories.filter { $0.isTopLevel }
                let subLevel = categories.filter { !$0.isTopLevel }

                HStack(spacing: 0) {
                    statItem(
                        value: "\(topLevel.count)",
                        label: "Top-level",
                        icon: "square.grid.2x2",
                        color: .accentColor
                    )

                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 1, height: 32)

                    statItem(
                        value: "\(subLevel.count)",
                        label: "Sub-level",
                        icon: "list.bullet",
                        color: .orange
                    )

                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 1, height: 32)

                    statItem(
                        value: "\(categories.count)",
                        label: "Total",
                        icon: "tray.full",
                        color: .green
                    )
                }
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground))
            }
        }
    }

    private func statItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(color)
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("No categories")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Tap + to add a category")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
            Spacer()
        }
    }

    @ViewBuilder
    private func categoryRow(category: Category) -> some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.callout)
                .frame(width: 36, height: 36)
                .foregroundStyle(.white)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.categoryColor(for: Int(category.sortOrder)))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(.body)

                if category.isSystem {
                    Text("Default")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if category.canDelete {
                Menu {
                    Button {
                        editingCategory = category
                        newCategoryName = category.name
                        newCategoryIcon = category.icon
                        showAddSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        _ = categoryVM.deleteCategory(category)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func categoryEditSheet() -> some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") { showAddSheet = false }
                Spacer()
                Text(editingCategory == nil ? "Add Category" : "Edit Category")
                    .font(.headline)
                Spacer()
                Button(editingCategory == nil ? "Add" : "Save") {
                    saveCategory()
                }
                .disabled(newCategoryName.isEmpty)
                .fontWeight(.semibold)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            TextField("Category name", text: $newCategoryName)
                .textFieldStyle(.roundedBorder)
                .focused($isEditNameFocused)
                .padding(.horizontal, 16)
                .padding(.top, 12)

            Text("Choose Icon")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)

            let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(iconOptions, id: \.self) { icon in
                        Image(systemName: icon)
                            .font(.callout)
                            .frame(width: 44, height: 44)
                            .foregroundStyle(icon == newCategoryIcon ? .white : .primary)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(icon == newCategoryIcon ? Color.accentColor : Color(.systemGray5))
                            )
                            .scaleEffect(icon == newCategoryIcon ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.15), value: newCategoryIcon)
                            .onTapGesture {
                                newCategoryIcon = icon
                            }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                isEditNameFocused = true
            }
        }
    }

    private func saveCategory() {
        guard let book = bookVM.currentBook else { return }

        if let category = editingCategory {
            if categoryVM.updateCategory(category, name: newCategoryName, icon: newCategoryIcon) {
                showAddSheet = false
            }
        } else {
            if categoryVM.addCategory(
                name: newCategoryName,
                icon: newCategoryIcon,
                type: selectedType,
                to: book
            ) {
                showAddSheet = false
            }
        }
    }
}
