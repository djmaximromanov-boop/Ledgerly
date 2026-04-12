import SwiftUI
import Charts

struct StatisticsView: View {
    @EnvironmentObject var bookVM: BookViewModel
    @StateObject private var statsVM = StatisticsViewModel()

    @State private var selectedTopCategory: Category? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    BookHeaderView()

                    periodPicker

                    if bookVM.currentBook != nil {
                        summarySection
                        trendSection
                        categoryPieSection

                        if bookVM.currentBook?.bookType == .shared {
                            memberComparisonSection
                        }
                    } else {
                        emptyStateView
                    }
                }
                .padding()
            }
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedTopCategory) { category in
                if let book = bookVM.currentBook {
                    CategoryDetailView(
                        category: category,
                        book: book,
                        statsVM: statsVM
                    )
                }
            }
            .onAppear {
                if let book = bookVM.currentBook {
                    statsVM.refreshData(for: book)
                }
            }
            .onChange(of: bookVM.currentBook?.id) { _, _ in
                if let book = bookVM.currentBook {
                    statsVM.refreshData(for: book)
                }
            }
            .onChange(of: statsVM.selectedPeriod) { _, _ in
                statsVM.refreshCurrentData()
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 40)

            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.08))
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(Color.accentColor.opacity(0.05))
                    .frame(width: 180, height: 180)
                    .offset(x: 20, y: -10)

                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.6), Color.accentColor.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("No ledger data yet")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("Create a ledger and start recording your finances\nEvery entry is the first step to financial management")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var periodPicker: some View {
        VStack(spacing: 8) {
            Picker("Period", selection: $statsVM.selectedPeriod) {
                ForEach(StatisticsViewModel.TimePeriod.allCases, id: \.self) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Button { statsVM.navigateBack() } label: {
                    Image(systemName: "chevron.left")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(statsVM.dateRangeLabel)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Button { statsVM.navigateForward() } label: {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var summarySection: some View {
        HStack(spacing: 12) {
            SummaryCard(title: "Expense", amount: statsVM.totalExpense, color: .red, icon: "arrowtriangle.down.fill", gradient: Color.expenseGradient)
            SummaryCard(title: "Income", amount: statsVM.totalIncome, color: .green, icon: "arrowtriangle.up.fill", gradient: Color.incomeGradient)
            SummaryCard(title: "Balance", amount: statsVM.totalBalance, color: .blue, icon: "equal", gradient: Color.balanceGradient)
        }
    }

    private var trendSection: some View {
        let data = statsVM.trendData

        return VStack(alignment: .leading, spacing: 8) {
            Text("Trend")
                .font(.headline)

            if data.isEmpty {
                Text("No data")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                Chart {
                    ForEach(data) { point in
                        let expD = Double(truncating: NSDecimalNumber(decimal: point.expense))
                        let incD = Double(truncating: NSDecimalNumber(decimal: point.income))
                        let balD = incD - expD

                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Expense", expD)
                        )
                        .foregroundStyle(Color.red)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2))

                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Expense", expD)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.red.opacity(0.15), Color.red.opacity(0.01)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Income", incD)
                        )
                        .foregroundStyle(Color.green)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2))

                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Income", incD)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.green.opacity(0.15), Color.green.opacity(0.01)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)

                        BarMark(
                            x: .value("Date", point.date),
                            y: .value("Balance", balD)
                        )
                        .foregroundStyle(balD >= 0 ? Color.blue.opacity(0.2) : Color.orange.opacity(0.2))
                        .cornerRadius(2)
                    }
                }
                .frame(height: 220)
                .id(statsVM.selectedPeriod)

                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.red)
                            .frame(width: 16, height: 3)
                        Text("Expense")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.green)
                            .frame(width: 16, height: 3)
                        Text("Income")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.blue.opacity(0.4))
                            .frame(width: 12, height: 8)
                        Text("Balance")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var categoryPieSection: some View {
        let categoryData = statsVM.expenseByCategory

        return VStack(alignment: .leading, spacing: 8) {
            Text("By Category")
                .font(.headline)

            if categoryData.isEmpty {
                Text("No data")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                Chart(categoryData, id: \.0.id) { category, amount in
                    SectorMark(
                        angle: .value("Amount", Double(truncating: NSDecimalNumber(decimal: amount))),
                        innerRadius: .ratio(0.5),
                        angularInset: 1.5
                    )
                    .foregroundStyle(Color.categoryColor(for: categoryData.firstIndex(where: { $0.0.id == category.id }) ?? 0))
                }
                .frame(height: 200)

                VStack(spacing: 8) {
                    ForEach(Array(categoryData.prefix(5).enumerated()), id: \.offset) { index, item in
                        Button {
                            selectedTopCategory = item.0
                        } label: {
                            categoryLegendRow(item: item, index: index)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func categoryLegendRow(item: (Category, Decimal), index: Int) -> some View {
        let total = statsVM.totalExpense
        let safePct: Double = {
            guard total > 0 else { return 0 }
            let result = Double(truncating: NSDecimalNumber(decimal: item.1 / total))
            return result.isFinite ? result : 0
        }()

        return HStack {
            Circle()
                .fill(Color.categoryColor(for: index))
                .frame(width: 10, height: 10)

            Text(item.0.name)
                .font(.subheadline)

            Spacer()

            if total > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(.systemGray5))
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.categoryColor(for: index).opacity(0.6))
                            .frame(width: geo.size.width * min(safePct, 1.0), height: 4)
                    }
                }
                .frame(width: 50, height: 4)

                Text(total > 0 ? (item.1 / total).percentageString : "0%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 42, alignment: .trailing)
            }

            Text(item.1.currencyString)
                .font(.subheadline)
                .fontWeight(.medium)

            let subs = statsVM.subCategories(of: item.0)
            if !subs.isEmpty {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
    }

    private var memberComparisonSection: some View {
        let memberData = statsVM.expenseByMember

        return VStack(alignment: .leading, spacing: 8) {
            Text("Member Spending")
                .font(.headline)

            if memberData.isEmpty {
                Text("No data")
                    .foregroundStyle(.secondary)
            } else {
                Chart(memberData, id: \.0.id) { member, amount in
                    let colorIndex = memberData.firstIndex(where: { $0.0.id == member.id }) ?? 0
                    let barColor = Color.categoryColor(for: colorIndex)

                    BarMark(
                        x: .value("Member", member.name),
                        y: .value("Amount", Double(truncating: NSDecimalNumber(decimal: amount)))
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [barColor, barColor.opacity(0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(4)
                }
                .frame(height: 150)
                .chartYAxisLabel("¥")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct CategoryDetailView: View {
    let category: Category
    let book: Book
    @ObservedObject var statsVM: StatisticsViewModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    subCategorySection()
                    transactionListSection()
                }
                .padding()
            }
            .navigationTitle(category.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func subCategorySection() -> some View {
        let subCategories = statsVM.expenseBySubCategory(parent: category)

        if !subCategories.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Subcategories")
                    .font(.headline)

                Chart(subCategories, id: \.0.id) { subCategory, amount in
                    BarMark(
                        x: .value("Amount", Double(truncating: NSDecimalNumber(decimal: amount))),
                        y: .value("Category", subCategory.name)
                    )
                    .foregroundStyle(Color.categoryColor(for: subCategories.firstIndex(where: { $0.0.id == subCategory.id }) ?? 0))
                    .cornerRadius(4)
                }
                .frame(height: CGFloat(subCategories.count) * 40)
                .chartXAxisLabel("¥")

                VStack(spacing: 8) {
                    ForEach(Array(subCategories.enumerated()), id: \.offset) { index, item in
                        HStack {
                            Circle()
                                .fill(Color.categoryColor(for: index))
                                .frame(width: 10, height: 10)

                            Text(item.0.name)
                                .font(.subheadline)

                            Spacer()

                            Text(item.1.currencyString)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    @ViewBuilder
    private func transactionListSection() -> some View {
        let transactions = statsVM.transactions(by: category)

        VStack(alignment: .leading, spacing: 8) {
            Text("Transactions")
                .font(.headline)

            if transactions.isEmpty {
                Text("No records")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(transactions, id: \.id) { transaction in
                    TransactionRow(transaction: transaction)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SummaryCard: View {
    let title: String
    let amount: Decimal
    let color: Color
    let icon: String
    let gradient: LinearGradient

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.white)
                .padding(4)
                .background(Circle().fill(color))

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(amount.currencyString)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(gradient.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }
}
