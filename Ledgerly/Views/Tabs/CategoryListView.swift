import SwiftUI
import CoreData

struct CategoryListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var bookVM: BookViewModel
    @EnvironmentObject var loc: LocalizationManager
    @StateObject private var categoryVM = CategoryViewModel()

    @State private var selectedType: CategoryType = .expense
    @State private var showAddSheet = false
    @State private var showSortSheet = false
    @State private var editingCategory: Category? = nil
    @State private var priorityCategory: Category? = nil
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
            .navigationTitle(loc["categories.title"])
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
            .alert(loc["categories.error"], isPresented: .constant(categoryVM.errorMessage != nil)) {
                Button(loc["categories.ok"]) { categoryVM.errorMessage = nil }
            } message: {
                Text(categoryVM.errorMessage ?? "")
            }
            .confirmationDialog(
                loc["categories.setPriority"],
                isPresented: .init(
                    get: { priorityCategory != nil },
                    set: { if !$0 { priorityCategory = nil } }
                ),
                titleVisibility: .visible
            ) {
                ForEach(Category.PriorityLevel.allCases, id: \.self) { level in
                    Button(priorityLabel(for: level)) {
                        if let cat = priorityCategory {
                            categoryVM.setPriority(cat, level: level)
                            priorityCategory = nil
                        }
                    }
                }
                Button(loc["categories.cancel"], role: .cancel) {
                    priorityCategory = nil
                }
            } message: {
                if let cat = priorityCategory {
                    Text("\(cat.name)")
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 0) {
            Picker(loc["categories.type"], selection: $selectedType) {
                Text(loc["categories.expense"]).tag(CategoryType.expense)
                Text(loc["categories.income"]).tag(CategoryType.income)
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
                        label: loc["categories.topLevel"],
                        icon: "square.grid.2x2",
                        color: .accentColor
                    )

                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 1, height: 32)

                    statItem(
                        value: "\(subLevel.count)",
                        label: loc["categories.subLevel"],
                        icon: "list.bullet",
                        color: .orange
                    )

                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 1, height: 32)

                    statItem(
                        value: "\(categories.count)",
                        label: loc["categories.total"],
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
            Text(loc["categories.empty"])
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(loc["categories.emptyHint"])
                .font(.subheadline)
                .foregroundStyle(.tertiary)
            Spacer()
        }
    }

    @ViewBuilder
    private func categoryRow(category: Category) -> some View {
        HStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: category.icon)
                    .font(.callout)
                    .frame(width: 36, height: 36)
                    .foregroundStyle(.white)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.categoryColor(for: Int(category.sortOrder)))
                    )

                if category.priorityLevel != .none {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(flagColor(for: category.priorityLevel))
                        .offset(x: 6, y: -6)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(category.name)
                        .font(.body)

                    if category.priorityLevel != .none {
                        Text(priorityLabel(for: category.priorityLevel))
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(flagColor(for: category.priorityLevel))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(flagColor(for: category.priorityLevel).opacity(0.12))
                            )
                    }
                }

                if category.isSystem {
                    Text(loc["categories.default"])
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
                        Label(loc["categories.edit"], systemImage: "pencil")
                    }

                    Button {
                        priorityCategory = category
                    } label: {
                        Label(loc["categories.setPriority"], systemImage: "flag")
                    }

                    Divider()

                    Button(role: .destructive) {
                        _ = categoryVM.deleteCategory(category)
                    } label: {
                        Label(loc["categories.delete"], systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onLongPressGesture {
            priorityCategory = category
        }
    }

    private func flagColor(for level: Category.PriorityLevel) -> Color {
        switch level {
        case .none: return .clear
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        }
    }

    private func priorityLabel(for level: Category.PriorityLevel) -> String {
        switch level {
        case .none: return loc["categories.priorityNone"]
        case .low: return loc["categories.priorityLow"]
        case .medium: return loc["categories.priorityMedium"]
        case .high: return loc["categories.priorityHigh"]
        }
    }

    @ViewBuilder
    private func categoryEditSheet() -> some View {
        VStack(spacing: 0) {
            HStack {
                Button(loc["categories.cancel"]) { showAddSheet = false }
                Spacer()
                Text(editingCategory == nil ? loc["categories.addCategory"] : loc["categories.editCategory"])
                    .font(.headline)
                Spacer()
                Button(editingCategory == nil ? loc["categories.add"] : loc["categories.save"]) {
                    saveCategory()
                }
                .disabled(newCategoryName.isEmpty)
                .fontWeight(.semibold)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            TextField(loc["categories.categoryName"], text: $newCategoryName)
                .textFieldStyle(.roundedBorder)
                .focused($isEditNameFocused)
                .padding(.horizontal, 16)
                .padding(.top, 12)

            Text(loc["categories.chooseIcon"])
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
