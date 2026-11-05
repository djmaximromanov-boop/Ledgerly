import SwiftUI

struct TransactionRow: View {
    @EnvironmentObject var loc: LocalizationManager
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: transaction.category?.icon ?? "questionmark")
                    .font(.callout)
                    .foregroundStyle(categoryColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.category?.displayName ?? loc["component.uncategorized"])
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 6) {
                    if let member = transaction.member {
                        HStack(spacing: 3) {
                            Circle()
                                .fill(memberColor(for: member))
                                .frame(width: 12, height: 12)
                                .overlay {
                                    Text(String(member.name.prefix(1)))
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundStyle(.white)
                                }

                            Text(member.name)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let note = transaction.note, !note.isEmpty {
                        if transaction.member != nil {
                            Text("·")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }

                        Text(note)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(amountText)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(amountColor)

                Text(transaction.date.formatted(.dateTime.locale(Language.current.locale).month().day()))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }

    private var categoryColor: Color {
        guard let category = transaction.category else { return .gray }
        let topId: UUID = category.isTopLevel ? category.id : (category.parentId ?? category.id)
        let index = abs(topId.hashValue) % 12
        return Color.categoryColor(for: index)
    }

    private func memberColor(for member: Member) -> Color {
        let index = abs(member.id.hashValue) % 8
        let colors: [Color] = [.blue, .purple, .orange, .pink, .teal, .indigo, .mint, .cyan]
        return colors[index]
    }

    private var amountText: String {
        let amount = transaction.amount as Decimal
        let prefix: String
        switch transaction.transactionType {
        case .expense: prefix = "-"
        case .income: prefix = "+"
        case .transfer: prefix = "↔ "
        }
        return prefix + amount.currencyString
    }

    private var amountColor: Color {
        switch transaction.transactionType {
        case .expense: return .red
        case .income: return .green
        case .transfer: return .orange
        }
    }
}
