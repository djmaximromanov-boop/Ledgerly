import SwiftUI

struct SettingsView: View {
    @AppStorage("currency") private var currency = "CNY"
    @AppStorage("defaultBookId") private var defaultBookId = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("General") {
                    Picker("Currency", selection: $currency) {
                        Text("CNY (¥)").tag("CNY")
                        Text("USD ($)").tag("USD")
                        Text("EUR (€)").tag("EUR")
                        Text("JPY (¥)").tag("JPY")
                    }
                }

                Section("Data") {
                    NavigationLink {
                        CategoryListView()
                    } label: {
                        Label("Categories", systemImage: "folder")
                    }

                    NavigationLink {
                        DataExportView()
                    } label: {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }

                    NavigationLink {
                        DataManageView()
                    } label: {
                        Label("Data Management", systemImage: "externaldrive")
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "https://github.com")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct DataExportView: View {
    @EnvironmentObject var bookVM: BookViewModel
    @State private var exportText = ""
    @State private var showShareSheet = false

    var body: some View {
        List {
            if let book = bookVM.currentBook {
                Section {
                    Button("Export as CSV") {
                        exportCSV(for: book)
                        showShareSheet = true
                    }

                    Button("Export as JSON") {
                        exportJSON(for: book)
                        showShareSheet = true
                    }
                }

                if !exportText.isEmpty {
                    Section("Preview") {
                        Text(exportText)
                            .font(.caption)
                            .monospaced()
                    }
                }
            }
        }
        .navigationTitle("Export Data")
        .sheet(isPresented: $showShareSheet) {
            if let data = exportText.data(using: .utf8) {
                ShareSheet(items: [data])
            }
        }
    }

    private func exportCSV(for book: Book) {
        let transactions = (book.transactions?.allObjects as? [Transaction]) ?? []
            .sorted { $0.date > $1.date }

        var csv = "Date,Type,Category,Amount,Note\n"
        for t in transactions {
            let type = t.transactionType == .expense ? "Expense" : "Income"
            let category = t.category?.name ?? ""
            let amount = (t.amount as Decimal).currencyString
            let note = t.note ?? ""
            csv += "\(t.date.formatted(.dateTime.year().month().day())),\(type),\(category),\(amount),\(note)\n"
        }
        exportText = csv
    }

    private func exportJSON(for book: Book) {
        let transactions = (book.transactions?.allObjects as? [Transaction]) ?? []
            .sorted { $0.date > $1.date }

        var items: [[String: Any]] = []
        for t in transactions {
            items.append([
                "date": t.date.formatted(.dateTime.year().month().day()),
                "type": t.transactionType == .expense ? "expense" : "income",
                "category": t.category?.name ?? "",
                "amount": String(describing: t.amount),
                "note": t.note ?? ""
            ])
        }

        if let data = try? JSONSerialization.data(withJSONObject: items, options: .prettyPrinted) {
            exportText = String(data: data, encoding: .utf8) ?? ""
        }
    }
}

struct DataManageView: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("iCloud Sync")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Data syncs automatically to iCloud, keeping consistent across devices")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Data Security")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("All data is stored only in your iCloud account and never uploaded to any third-party servers")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Data Management")
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

