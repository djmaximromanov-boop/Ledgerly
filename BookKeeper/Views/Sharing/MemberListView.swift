import SwiftUI

struct MemberListView: View {
    let book: Book
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
                    Text("\(members.count) members")
                }
            }

            if book.bookType == .shared {
                Section {
                    Button {
                        showInviteSheet = true
                    } label: {
                        Label("Invite Member", systemImage: "person.badge.plus")
                    }

                    NavigationLink {
                        ShareBookView(book: book)
                    } label: {
                        Label("Share via iCloud", systemImage: "icloud.and.arrow.up")
                    }
                } header: {
                    Text("Invite")
                }
            }

            Section {
                Button {
                    showAddMember = true
                } label: {
                    Label("Add Local Member", systemImage: "plus.circle")
                }
            } header: {
                Text("Manual Add")
            }
        }
        .navigationTitle("Members")
        .alert("Add Member", isPresented: $showAddMember) {
            TextField("Member name", text: $newMemberName)
            Picker("Role", selection: $newMemberRole) {
                Text("Editor").tag(MemberRole.editor)
                Text("Viewer").tag(MemberRole.viewer)
            }
            Button("Cancel", role: .cancel) { newMemberName = "" }
            Button("Add") { addMember() }
                .disabled(newMemberName.isEmpty)
        } message: {
            Text("Enter the new member's name")
        }
        .alert("Invite Member", isPresented: $showInviteSheet) {
            TextField("Member name", text: $newMemberName)
            Picker("Role", selection: $newMemberRole) {
                Text("Editor · Can record").tag(MemberRole.editor)
                Text("Viewer · Read only").tag(MemberRole.viewer)
            }
            Button("Cancel", role: .cancel) { newMemberName = "" }
            Button("Invite") { addMember() }
                .disabled(newMemberName.isEmpty)
        } message: {
            Text("Enter the member name to invite. After adding, sync via iCloud sharing.")
        }
        .alert("Confirm Delete", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { memberToDelete = nil }
            Button("Delete", role: .destructive) {
                if let member = memberToDelete {
                    deleteMember(member)
                }
            }
        } message: {
            if let member = memberToDelete {
                Text("Are you sure you want to delete member「\(member.name)」? Associated records will be kept.")
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
                Text("Owner")
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
            Label("Editor", systemImage: member.memberRole == .editor ? "checkmark" : "")
        }
        Button {
            updateRole(member, to: .viewer)
        } label: {
            Label("Viewer", systemImage: member.memberRole == .viewer ? "checkmark" : "")
        }
    }

    @ViewBuilder
    private func deleteButton(for member: Member) -> some View {
        Button(role: .destructive) {
            memberToDelete = member
            showDeleteConfirm = true
        } label: {
            Label("Delete Member", systemImage: "trash")
        }
    }

    private func roleText(for role: MemberRole) -> String {
        switch role {
        case .owner: return "Owner · Can manage members"
        case .editor: return "Editor · Can record"
        case .viewer: return "Viewer · Read only"
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
