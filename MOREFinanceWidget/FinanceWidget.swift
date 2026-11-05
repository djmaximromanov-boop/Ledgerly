import SwiftUI
import WidgetKit

private struct FinanceWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: FinanceWidgetSnapshot
}

private struct FinanceWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> FinanceWidgetEntry {
        FinanceWidgetEntry(date: .now, snapshot: .empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (FinanceWidgetEntry) -> Void) {
        completion(FinanceWidgetEntry(date: .now, snapshot: FinanceWidgetSnapshotStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FinanceWidgetEntry>) -> Void) {
        let now = Date()
        let entry = FinanceWidgetEntry(date: now, snapshot: FinanceWidgetSnapshotStore.load())
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now.addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

@main
struct FinanceWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: FinanceWidgetSnapshotStore.widgetKind,
            provider: FinanceWidgetProvider()
        ) { entry in
            FinanceWidgetView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("MORE Finance")
        .description("Расходы за месяц и остаток счетов")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct FinanceWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let snapshot: FinanceWidgetSnapshot

    var body: some View {
        Group {
            if family == .systemSmall {
                smallLayout
            } else {
                mediumLayout
            }
        }
        .padding(14)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color(red: 0.13, green: 0.14, blue: 0.18), Color(red: 0.05, green: 0.06, blue: 0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(snapshot.hasBook ? "РАСХОДЫ ЗА МЕСЯЦ" : "MORE FINANCE")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.65))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(snapshot.hasBook ? money(snapshot.expensesThisMonth) : "Откройте приложение")
                .font(.system(size: snapshot.hasBook ? 21 : 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 1, green: 0.36, blue: 0.34))
                .lineLimit(1)
                .minimumScaleFactor(0.55)

            Spacer(minLength: 0)
            Rectangle().fill(.white.opacity(0.14)).frame(height: 1)
            Text("НА СЧЕТАХ")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.65))
            Text(money(snapshot.totalAccountBalance))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.94, green: 0.25, blue: 0.57))
                .lineLimit(1)
                .minimumScaleFactor(0.55)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var mediumLayout: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(snapshot.hasBook ? snapshot.bookName : "MORE Finance")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.65))
                .lineLimit(1)
            HStack(alignment: .center, spacing: 12) {
                metric(title: "РАСХОДЫ", value: snapshot.expensesThisMonth, color: Color(red: 1, green: 0.36, blue: 0.34))
                metric(title: "ДОХОДЫ", value: snapshot.incomeThisMonth, color: Color(red: 0.40, green: 0.84, blue: 0.60))
                metric(title: "НА СЧЕТАХ", value: snapshot.totalAccountBalance, color: Color(red: 0.94, green: 0.25, blue: 0.57))
            }
            Spacer(minLength: 0)
            Text("Текущий месяц · \(snapshot.updatedAt.formatted(.dateTime.locale(Locale(identifier: "ru_RU")).day().month(.abbreviated)))")
                .font(.system(size: 10, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.42))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func metric(title: String, value: Decimal, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.62))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(money(value))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func money(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.numberStyle = .currency
        formatter.currencyCode = snapshot.currencyCode
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "0 ₽"
    }
}
