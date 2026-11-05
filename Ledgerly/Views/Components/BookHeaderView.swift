import SwiftUI
import CoreData

struct BookHeaderView: View {
    @EnvironmentObject var bookVM: BookViewModel
    @EnvironmentObject var loc: LocalizationManager

    var body: some View {
        if let book = bookVM.currentBook {
            HStack(spacing: 12) {
                Image(systemName: book.icon)
                    .font(.title)
                    .frame(width: 44, height: 44)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(book.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)

                    HStack(spacing: 4) {
                        Text(book.bookType == .personal ? loc["quickEntry.personal"] : loc["quickEntry.shared"])
                            .font(.caption)

                        if book.bookType == .shared {
                            Image(systemName: "person.2")
                                .font(.caption)
                        }
                    }
                    .foregroundStyle(.secondary)
                }

                Spacer()

                let members = book.members?.allObjects as? [Member] ?? []
                if !members.isEmpty {
                    HStack(spacing: -6) {
                        ForEach(Array(members.prefix(5)), id: \.id) { member in
                            Circle()
                                .fill(memberColor(for: member))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Text(String(member.name.prefix(1)))
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color(.systemBackground), lineWidth: 2)
                                )
                        }
                        if members.count > 5 {
                            Circle()
                                .fill(Color(.systemGray4))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Text("+\(members.count - 5)")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(.secondary)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color(.systemBackground), lineWidth: 2)
                                )
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private func memberColor(for member: Member) -> Color {
        let colors: [Color] = [.blue, .purple, .orange, .pink, .teal, .indigo, .mint, .cyan]
        let index = abs(member.id.hashValue) % colors.count
        return colors[index]
    }
}
