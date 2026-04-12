import SwiftUI
import Charts

struct MemberComparisonChart: View {
    let data: [(member: String, amount: Decimal, color: Color)]

    var body: some View {
        Chart(data, id: \.member) { item in
            BarMark(
                x: .value("Member", item.member),
                y: .value("Amount", Double(truncating: NSDecimalNumber(decimal: item.amount)))
            )
            .foregroundStyle(item.color)
            .cornerRadius(6)
        }
        .frame(height: 150)
        .chartYAxisLabel("¥")
    }
}
