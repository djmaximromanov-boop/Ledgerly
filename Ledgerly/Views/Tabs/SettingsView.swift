import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @AppStorage("currency") private var currency = "RUB"
    @AppStorage("defaultBookId") private var defaultBookId = ""
    @EnvironmentObject var loc: LocalizationManager

    var body: some View {
        NavigationStack {
            Form {
                Section(loc["settings.general"]) {
                    Picker(loc["settings.currency"], selection: $currency) {
                        Text(loc["settings.rub"]).tag("RUB")
                        Text(loc["settings.cny"]).tag("CNY")
                        Text(loc["settings.usd"]).tag("USD")
                        Text(loc["settings.eur"]).tag("EUR")
                        Text(loc["settings.jpy"]).tag("JPY")
                    }

                    Picker(loc["settings.language"], selection: $loc.language) {
                        ForEach(Language.allCases, id: \.self) { lang in
                            Text(lang.nativeDisplayName).tag(lang)
                        }
                    }
                }

                Section(loc["settings.data"]) {
                    NavigationLink {
                        CategoryListView()
                    } label: {
                        Label(loc["settings.categories"], systemImage: "folder")
                    }

                    NavigationLink {
                        DataExportView()
                    } label: {
                        Label(loc["settings.exportData"], systemImage: "square.and.arrow.up")
                    }

                    NavigationLink {
                        DataImportView()
                    } label: {
                        Label(loc["settings.importData"], systemImage: "square.and.arrow.down")
                    }

                    NavigationLink {
                        DataManageView()
                    } label: {
                        Label(loc["settings.dataManagement"], systemImage: "externaldrive")
                    }
                }

                Section(loc["settings.about"]) {
                    HStack {
                        Text(loc["settings.version"])
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "https://github.com")!) {
                        HStack {
                            Text(loc["settings.privacyPolicy"])
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(loc["settings.title"])
        }
    }
}

struct DataImportView: View {
    @EnvironmentObject var bookVM: BookViewModel
    @EnvironmentObject var loc: LocalizationManager

    @State private var showFileImporter = false
    @State private var importMessage: String?
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(loc["settings.importMoneyOK"])
                        .font(.subheadline.weight(.medium))
                    Text(loc["settings.importDesc"])
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button {
                    showFileImporter = true
                } label: {
                    Label(loc["settings.chooseCSV"], systemImage: "doc.badge.plus")
                }
            }

            if let importMessage {
                Section(loc["settings.importResult"]) {
                    Text(importMessage)
                        .font(.subheadline)
                }
            }
        }
        .navigationTitle(loc["settings.importData"])
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.data, .text, .commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .alert(loc["settings.importError"], isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button(loc["categories.ok"], role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing { url.stopAccessingSecurityScopedResource() }
        }

        do {
            let summary = try MoneyOKImportService.importFile(
                at: url,
                into: PersistenceController.shared.viewContext
            )
            bookVM.fetchBooks()
            bookVM.currentBook = summary.book
            importMessage = String(
                format: loc["settings.importSummary"],
                summary.importedTransactions,
                summary.importedTransfers,
                summary.appliedBalances,
                summary.createdAccounts,
                summary.createdCategories,
                summary.skippedRows
            )
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

struct DataExportView: View {
    @EnvironmentObject var bookVM: BookViewModel
    @EnvironmentObject var loc: LocalizationManager
    @State private var exportText = ""
    @State private var showShareSheet = false

    var body: some View {
        List {
            if let book = bookVM.currentBook {
                Section {
                    Button(loc["settings.exportCSV"]) {
                        exportCSV(for: book)
                        showShareSheet = true
                    }

                    Button(loc["settings.exportJSON"]) {
                        exportJSON(for: book)
                        showShareSheet = true
                    }
                }

                if !exportText.isEmpty {
                    Section(loc["settings.preview"]) {
                        Text(exportText)
                            .font(.caption)
                            .monospaced()
                    }
                }
            }
        }
        .navigationTitle(loc["settings.exportData"])
        .sheet(isPresented: $showShareSheet) {
            if let data = exportText.data(using: .utf8) {
                ShareSheet(items: [data])
            }
        }
    }

    private func exportCSV(for book: Book) {
        let transactions = (book.transactions?.allObjects as? [Transaction]) ?? []
            .sorted { $0.date > $1.date }

        var csv = "\(loc["stats.date"]),\(loc["categories.type"]),\(loc["stats.category"]),\(loc["ledgers.amount"]),\(loc["quickEntry.note"])\n"
        for t in transactions {
            let type: String
            switch t.transactionType {
            case .expense: type = loc["categories.expense"]
            case .income: type = loc["categories.income"]
            case .transfer: type = loc["categories.transfer"]
            }
            let category = t.category?.displayName ?? ""
            let amount = (t.amount as Decimal).currencyString
            let note = t.note ?? ""
            let fields = [t.date.formatted(.dateTime.locale(Language.current.locale).year().month().day()), type, category, amount, note]
            csv += fields.map { "\"" + $0.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }.joined(separator: ",") + "\n"
        }
        exportText = csv
    }

    private func exportJSON(for book: Book) {
        let transactions = (book.transactions?.allObjects as? [Transaction]) ?? []
            .sorted { $0.date > $1.date }

        var items: [[String: Any]] = []
        for t in transactions {
            items.append([
                "date": t.date.formatted(.dateTime.locale(Language.current.locale).year().month().day()),
                "type": t.transactionType.rawValue,
                "category": t.category?.displayName ?? "",
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
    @EnvironmentObject var loc: LocalizationManager

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(loc["settings.iCloudSync"])
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(loc["settings.iCloudSyncDesc"])
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(loc["settings.dataSecurity"])
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(loc["settings.dataSecurityDesc"])
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(loc["settings.dataManagement"])
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
