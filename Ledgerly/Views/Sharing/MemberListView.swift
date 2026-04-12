import SwiftUI

struct MemberListView: View {
    let book: Book
    @EnvironmentObject var loc: LocalizationManager
    @State private var showAddMember = false
    @State private var showInviteSheet = false
    @State private var newMemberName = ""
    @State private var newMemberRole: MemberRole = .editor
    @State private var memberToDelete: Member?
    @State private var showDeleteConfirm = false

    private var members: [Member] {
        (book.members?.allObjects as? [Member] ?? [])
            .sorted { $0.memberRole == .owner && $1.memberRole != .owner }
    }

    private var isOwner: Bool {
        members.first(where: { $0.memberRole == .owner }) != nil
    }

    var body: some View {
        List {
            Section {
                ForEach(members, id: \.id) { member in
                    memberRow(member)
                }
            } header: {
                if book.bookType == .shared {
                    Text(String(format: loc["members.count"], members.count))
                }
            }

            if book.bookType == .shared {
                Section {
                    Button {
                        showInviteSheet = true
                    } label: {
                        Label(loc["members.inviteMember"], systemImage: "person.badge.plus")
                    }

                    NavigationLink {
                        ShareBookView(book: book)
                    } label: {
                        Label(loc["members.shareViaICloud"], systemImage: "icloud.and.arrow.up")
                    }
                } header: {
                    Text(loc["members.invite"])
                }
            }

            Section {
                Button {
                    showAddMember = true
                } label: {
                    Label(loc["members.addLocalMember"], systemImage: "plus.circle")
                }
            } header: {
                Text(loc["members.manualAdd"])
            }
        }
        .navigationTitle(loc["members.title"])
        .alert(loc["members.addMember"], isPresented: $showAddMember) {
            TextField(loc["members.memberName"], text: $newMemberName)
            Picker(loc["members.role"], selection: $newMemberRole) {
                Text(loc["members.editor"]).tag(MemberRole.editor)
                Text(loc["members.viewer"]).tag(MemberRole.viewer)
            }
            Button(loc["members.cancel"], role: .cancel) { newMemberName = "" }
            Button(loc["members.add"]) { addMember() }
                .disabled(newMemberName.isEmpty)
        } message: {
            Text(loc["members.enterName"])
        }
        .alert(loc["members.inviteMember"], isPresented: $showInviteSheet) {
            TextField(loc["members.memberName"], text: $newMemberName)
            Picker(loc["members.role"], selection: $newMemberRole) {
                Text(loc["members.editorCanRecord"]).tag(MemberRole.editor)
                Text(loc["members.viewerReadOnly"]).tag(MemberRole.viewer)
            }
            Button(loc["members.cancel"], role: .cancel) { newMemberName = "" }
            Button(loc["members.inviteMember"]) { addMember() }
                .disabled(newMemberName.isEmpty)
        } message: {
            Text(loc["members.inviteDesc"])
        }
        .alert(loc["members.confirmDelete"], isPresented: $showDeleteConfirm) {
            Button(loc["members.cancel"], role: .cancel) { memberToDelete = nil }
            Button(loc["members.delete"], role: .destructive) {
                if let member = memberToDelete {
                    deleteMember(member)
                }
            }
        } message: {
            if let member = memberToDelete {
                Text(String(format: loc["members.deleteConfirm"], member.name))
            }
        }
    }

    @ViewBuilder
    private func memberRow(_ member: Member) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.categoryColor(for: members.firstIndex(where: { $0.id == member.id }) ?? 0))
                .frame(width: 40, height: 40)
                .overlay {
                    Text(String(member.name.prefix(1)))
                        .font(.headline)
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(member.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 4) {
                    Circle()
                        .fill(roleColor(for: member.memberRole))
                        .frame(width: 6, height: 6)
                    Text(roleText(for: member.memberRole))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if member.memberRole == .owner {
                Text(loc["members.owner"])
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.accentColor.opacity(0.1))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(Capsule())
            } else {
                Menu {
                    roleMenu(for: member)
                    Divider()
                    deleteButton(for: member)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func roleMenu(for member: Member) -> some View {
        Button {
            updateRole(member, to: .editor)
        } label: {
            Label(loc["members.editor"], systemImage: member.memberRole == .editor ? "checkmark" : "")
        }
        Button {
            updateRole(member, to: .viewer)
        } label: {
            Label(loc["members.viewer"], systemImage: member.memberRole == .viewer ? "checkmark" : "")
        }
    }

    @ViewBuilder
    private func deleteButton(for member: Member) -> some View {
        Button(role: .destructive) {
            memberToDelete = member
            showDeleteConfirm = true
        } label: {
            Label(loc["members.deleteMember"], systemImage: "trash")
        }
    }

    private func roleText(for role: MemberRole) -> String {
        switch role {
        case .owner: return loc["members.ownerCanManage"]
        case .editor: return loc["members.editorCanRecord"]
        case .viewer: return loc["members.viewerReadOnly"]
        }
    }

    private func roleColor(for role: MemberRole) -> Color {
        switch role {
        case .owner: return .blue
        case .editor: return .green
        case .viewer: return .orange
        }
    }

    private func addMember() {
        guard !newMemberName.isEmpty else { return }
        let context = PersistenceController.shared.viewContext
        let _ = Member.create(
            in: context,
            name: newMemberName,
            book: book,
            role: newMemberRole
        )
        PersistenceController.shared.save()
        newMemberName = ""
        newMemberRole = .editor
    }

    private func updateRole(_ member: Member, to role: MemberRole) {
        member.memberRole = role
        PersistenceController.shared.save()
    }

    private func deleteMember(_ member: Member) {
        PersistenceController.shared.delete(member)
        memberToDelete = nil
    }
}
