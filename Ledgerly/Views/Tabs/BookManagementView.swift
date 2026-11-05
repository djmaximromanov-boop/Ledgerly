import SwiftUI

struct BookManagementView: View {
    @EnvironmentObject var bookVM: BookViewModel
    @EnvironmentObject var loc: LocalizationManager
    @StateObject private var budgetVM = BudgetViewModel()
    @State private var showAddBudget = false
    @State private var newBudgetAmount = ""
    @State private var newBudgetPeriod = BudgetPeriod.monthly
    @Namespace private var bookSwitchNamespace

    var body: some View {
        NavigationStack {
            List {
                personalBooksSection
                sharedBooksSection
                budgetSection
            }
            .navigationTitle(loc["ledgers.title"])
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            bookVM.newBookType = .personal
                            bookVM.showCreateSheet = true
                        } label: {
                            Label(loc["ledgers.personal"], systemImage: "person")
                        }
                        Button {
                            bookVM.newBookType = .shared
                            bookVM.showCreateSheet = true
                        } label: {
                            Label(loc["ledgers.shared"], systemImage: "person.2")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $bookVM.showCreateSheet) {
                CreateBookView()
            }
            .alert(loc["ledgers.addBudget"], isPresented: $showAddBudget) {
                TextField(loc["ledgers.amount"], text: $newBudgetAmount)
                    .keyboardType(.decimalPad)
                Picker(loc["ledgers.period"], selection: $newBudgetPeriod) {
                    Text(loc["ledgers.monthly"]).tag(BudgetPeriod.monthly)
                    Text(loc["ledgers.yearly"]).tag(BudgetPeriod.yearly)
                }
                Button(loc["ledgers.cancel"], role: .cancel) { newBudgetAmount = "" }
                Button(loc["ledgers.add"]) {
                    if let book = bookVM.currentBook,
                       let amount = Decimal(string: newBudgetAmount), amount > 0 {
                        budgetVM.createBudget(for: book, amount: amount, period: newBudgetPeriod)
                    }
                    newBudgetAmount = ""
                }
            } message: {
                Text(loc["ledgers.enterBudgetAmount"])
            }
            .onChange(of: bookVM.currentBook) { _, newBook in
                if let book = newBook {
                    budgetVM.fetchBudgets(for: book)
                }
            }
        }
    }

    private var personalBooksSection: some View {
        Section {
            let personalBooks = bookVM.books.filter { $0.bookType == .personal }
            ForEach(personalBooks, id: \.id) { book in
                BookRow(book: book, isSelected: bookVM.currentBook?.id == book.id)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            bookVM.switchBook(to: book)
                        }
                    }
            }
            .onDelete { indexSet in
                let books = personalBooks
                for index in indexSet {
                    bookVM.deleteBook(books[index])
                }
            }
        } header: {
            Label(loc["ledgers.personal"], systemImage: "person")
        }
    }

    private var sharedBooksSection: some View {
        Section {
            let sharedBooks = bookVM.books.filter { $0.bookType == .shared }
            ForEach(sharedBooks, id: \.id) { book in
                BookRow(book: book, isSelected: bookVM.currentBook?.id == book.id)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            bookVM.switchBook(to: book)
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        NavigationLink {
                            MemberListView(book: book)
                        } label: {
                            Label(loc["ledgers.members"], systemImage: "person.2")
                        }
                        .tint(.blue)
                    }
            }
            .onDelete { indexSet in
                let books = sharedBooks
                for index in indexSet {
                    bookVM.deleteBook(books[index])
                }
            }
        } header: {
            Label(loc["ledgers.shared"], systemImage: "person.2")
        }
    }

    private var budgetSection: some View {
        Section {
            if let book = bookVM.currentBook {
                ForEach(budgetVM.budgets, id: \.id) { budget in
                    BudgetProgressView(
                        budget: budget,
                        spent: budgetVM.spentAmount(for: budget, in: book),
                        total: budget.amount as Decimal
                    )
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        budgetVM.deleteBudget(budgetVM.budgets[index])
                    }
                }

                Button {
                    showAddBudget = true
                } label: {
                    Label(loc["ledgers.addBudget"], systemImage: "plus.circle")
                }
            }
        } header: {
            Label(loc["ledgers.budgets"], systemImage: "target")
        }
    }
}

struct BookRow: View {
    @EnvironmentObject var loc: LocalizationManager
    let book: Book
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3)
                .fill(
                    LinearGradient(
                        colors: [Color.accentColor, Color.accentColor.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 4)
                .opacity(isSelected ? 1 : 0)
                .padding(.trailing, 10)

            Image(systemName: book.icon)
                .font(.title3)
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(book.displayName)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)

                let memberCount = book.members?.count ?? 0
                if book.bookType == .shared && memberCount > 0 {
                    Text(String(format: loc["ledgers.memberCount"], memberCount))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.caption)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(
            Group {
                if isSelected {
                    LinearGradient(
                        colors: [Color.accentColor.opacity(0.12), Color.accentColor.opacity(0.04)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                } else {
                    Color.clear
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(
            color: isSelected ? Color.accentColor.opacity(0.15) : Color.black.opacity(0.06),
            radius: isSelected ? 4 : 3,
            x: 0,
            y: isSelected ? 2 : 1
        )
        .animation(.easeInOut(duration: 0.25), value: isSelected)
    }
}

struct CreateBookView: View {
    @EnvironmentObject var bookVM: BookViewModel
    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    let icons = ["book.fill", "house.fill", "airplane.departure", "cart.fill", "briefcase.fill", "heart.fill", "star.fill", "flag.fill", "wallet.pass.fill", "creditcard.fill", "pawprint.fill", "person.2.fill"]
    @State private var iconScale: [String: CGFloat] = [:]

    var body: some View {
        NavigationStack {
            Form {
                Section(loc["ledgers.basicInfo"]) {
                    TextField(loc["ledgers.ledgerName"], text: $bookVM.newBookName)

                    HStack(spacing: 12) {
                        BookTypeCard(
                            type: .personal,
                            icon: "person.fill",
                            title: loc["ledgers.personal"],
                            subtitle: loc["ledgers.privateTracking"],
                            isSelected: bookVM.newBookType == .personal
                        ) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                bookVM.newBookType = .personal
                            }
                        }

                        BookTypeCard(
                            type: .shared,
                            icon: "person.2.fill",
                            title: loc["ledgers.shared"],
                            subtitle: loc["ledgers.teamCollaboration"],
                            isSelected: bookVM.newBookType == .shared
                        ) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                bookVM.newBookType = .shared
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }

                Section(loc["ledgers.icon"]) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .background(
                                    bookVM.newBookIcon == icon
                                        ? Color.accentColor.opacity(0.15)
                                        : Color(.systemGray6)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .scaleEffect(bookVM.newBookIcon == icon ? (iconScale[icon] ?? 1.0) : 1.0)
                                .onTapGesture {
                                    iconScale[icon] = 1.25
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                                        bookVM.newBookIcon = icon
                                        iconScale[icon] = 1.0
                                    }
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(loc["ledgers.newLedger"])
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(loc["ledgers.cancel"]) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(loc["ledgers.create"]) {
                        if !bookVM.newBookName.isEmpty {
                            bookVM.createBook()
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(bookVM.newBookName.isEmpty)
                }
            }
        }
    }
}

struct BookTypeCard: View {
    let type: BookType
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : Color.accentColor)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle().fill(isSelected ? Color.accentColor : Color.accentColor.opacity(0.12))
                    )

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(isSelected ? .primary : .secondary)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.08) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
