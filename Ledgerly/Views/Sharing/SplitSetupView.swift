import SwiftUI

struct SplitSetupView: View {
    let transaction: Transaction
    let book: Book
    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    @State private var splitMode: SplitMode = .equal
    @State private var selectedMembers: Set<UUID> = []
    @State private var customRatios: [UUID: Double] = [:]

    enum SplitMode: String, CaseIterable {
        case equal = "Equal Split"
        case custom = "Custom Ratio"
    }

    private var members: [Member] {
        (book.members?.allObjects as? [Member] ?? [])
    }

    private var totalAmount: Decimal {
        transaction.amount as Decimal
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(loc["split.method"]) {
                    Picker(loc["split.methodLabel"], selection: $splitMode) {
                        ForEach(SplitMode.allCases, id: \.self) { mode in
                            Text(mode == .equal ? loc["split.equalSplit"] : loc["split.customRatio"]).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(loc["split.selectMembers"]) {
                    ForEach(members, id: \.id) { member in
                        HStack {
                            Image(systemName: selectedMembers.contains(member.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedMembers.contains(member.id) ? Color.accentColor : .secondary)

                            Text(member.name)

                            Spacer()

                            if selectedMembers.contains(member.id) {
                                if splitMode == .equal {
                                    Text(perPersonAmount.currencyString)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    TextField(loc["split.ratio"], value: Binding(
                                        get: { customRatios[member.id] ?? 1.0 },
                                        set: { customRatios[member.id] = $0 }
                                    ), format: .number)
                                    .keyboardType(.decimalPad)
                                    .frame(width: 60)
                                    .font(.caption)
                                }
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleMember(member.id)
                        }
                    }
                }

                Section(loc["split.details"]) {
                    HStack {
                        Text(loc["split.total"])
                        Spacer()
                        Text(totalAmount.currencyString)
                            .fontWeight(.medium)
                    }

                    ForEach(members.filter { selectedMembers.contains($0.id) }, id: \.id) { member in
                        HStack {
                            Text(member.name)
                            Spacer()
                            Text(memberShare(memberId: member.id).currencyString)
                        }
                    }
                }
            }
            .navigationTitle(loc["split.title"])
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(loc["split.cancel"]) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(loc["split.save"]) {
                        saveSplit()
                        dismiss()
                    }
                    .disabled(selectedMembers.isEmpty)
                }
            }
            .onAppear {
                for member in members {
                    selectedMembers.insert(member.id)
                    customRatios[member.id] = 1.0
                }
            }
        }
    }

    private var perPersonAmount: Decimal {
        guard !selectedMembers.isEmpty else { return 0 }
        return totalAmount / Decimal(selectedMembers.count)
    }

    private func memberShare(memberId: UUID) -> Decimal {
        guard !selectedMembers.isEmpty else { return 0 }
        if splitMode == .equal {
            return perPersonAmount
        } else {
            let totalRatio = selectedMembers.reduce(0.0) { sum, id in
                sum + (customRatios[id] ?? 0)
            }
            guard totalRatio > 0 else { return 0 }
            let memberRatio = customRatios[memberId] ?? 0
            return totalAmount * Decimal(memberRatio / totalRatio)
        }
    }

    private func toggleMember(_ memberId: UUID) {
        if selectedMembers.contains(memberId) {
            selectedMembers.remove(memberId)
            customRatios.removeValue(forKey: memberId)
        } else {
            selectedMembers.insert(memberId)
            customRatios[memberId] = 1.0
        }
    }

    private func saveSplit() {
        let context = PersistenceController.shared.viewContext

        let existingSplits = (transaction.splitRecords?.allObjects as? [SplitRecord]) ?? []
        for split in existingSplits {
            context.delete(split)
        }

        for memberId in selectedMembers {
            guard let member = members.first(where: { $0.id == memberId }) else { continue }
            let shareAmount = memberShare(memberId: memberId)
            let totalRatio = selectedMembers.reduce(0.0) { sum, id in sum + (customRatios[id] ?? 0) }
            let ratio = splitMode == .equal
                ? 1.0 / Double(selectedMembers.count)
                : (customRatios[memberId] ?? 0) / totalRatio

            let _ = SplitRecord.create(
                in: context,
                transaction: transaction,
                member: member,
                shareAmount: shareAmount,
                shareRatio: ratio
            )
        }

        PersistenceController.shared.save()
    }
}

