import SwiftUI
import Charts

struct MemberComparisonChart: View {
    let data: [(member: String, amount: Decimal, color: Color)]

    var body: some View {
        Chart(data, id: \.member) { item in
            BarMark(
                x: .value(LocalizationManager.localized("stats.member"), item.member),
                y: .value(LocalizationManager.localized("stats.amount"), Double(truncating: NSDecimalNumber(decimal: item.amount)))
            )
            .foregroundStyle(item.color)
            .cornerRadius(6)
        }
        .frame(height: 150)
        .chartYAxisLabel(MoneyFormatting.symbol)
    }
}
