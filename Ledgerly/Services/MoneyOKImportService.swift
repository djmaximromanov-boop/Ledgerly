import Foundation
import CoreData

struct MoneyOKImportSummary {
    let book: Book
    let importedTransactions: Int
    let importedTransfers: Int
    let appliedBalances: Int
    let createdAccounts: Int
    let createdCategories: Int
    let skippedRows: Int
}

enum MoneyOKImportError: LocalizedError {
    case unreadableFile
    case emptyFile
    case missingColumns
    case unsupportedCurrency(Set<String>)
    case invalidRows([Int])
    case saveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .unreadableFile:
            return "Не удалось прочитать файл как UTF-8."
        case .emptyFile:
            return "Файл не содержит данных."
        case .missingColumns:
            return "Не найдены обязательные столбцы MoneyOK."
        case .unsupportedCurrency(let currencies):
            return "В файле найдены неподдерживаемые валюты: \(currencies.sorted().joined(separator: ", "))."
        case .invalidRows(let rows):
            let preview = rows.prefix(8).map(String.init).joined(separator: ", ")
            return "Не удалось разобрать строки CSV: \(preview)."
        case .saveFailed(let error):
            return "Не удалось сохранить импорт: \(error.localizedDescription)"
        }
    }
}

@MainActor
enum MoneyOKImportService {
    private struct Row {
        let date: Date
        let amount: Decimal
        let currency: String
        let account: String
        let article: String
        let group: String
        let comment: String
        let sourceLine: Int
    }

    private static let dateFormats = ["yyyy.MM.dd", "yyyy-MM-dd", "dd.MM.yyyy", "dd/MM/yyyy"]

    static func importFile(at url: URL, into context: NSManagedObjectContext) throws -> MoneyOKImportSummary {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw MoneyOKImportError.unreadableFile
        }

        guard var text = String(data: data, encoding: .utf8) else {
            throw MoneyOKImportError.unreadableFile
        }
        if text.first == "\u{FEFF}" {
            text.removeFirst()
        }

        let delimiter: Character = {
            let header = text.split(whereSeparator: { $0 == "\n" || $0 == "\r" }).first.map(String.init) ?? ""
            if header.contains("\t") { return "\t" }
            if header.contains(";") { return ";" }
            return ","
        }()

        let table = parseDelimited(text, delimiter: delimiter)
        guard let header = table.first, !header.isEmpty else {
            throw MoneyOKImportError.emptyFile
        }

        let normalizedHeaders = header.map(normalize)
        guard
            let dateIndex = index(of: ["дата", "date"], in: normalizedHeaders),
            let amountIndex = index(of: ["сумма", "amount"], in: normalizedHeaders),
            let currencyIndex = index(of: ["валюта", "currency"], in: normalizedHeaders),
            let accountIndex = index(of: ["счет", "счёт", "account"], in: normalizedHeaders),
            let articleIndex = index(of: ["статья", "category", "article"], in: normalizedHeaders)
        else {
            throw MoneyOKImportError.missingColumns
        }
        let groupIndex = index(of: ["группа статей", "группа", "group"], in: normalizedHeaders)
        let commentIndex = index(of: ["комментарий", "comment", "note"], in: normalizedHeaders)

        var rows: [Row] = []
        var invalidLineNumbers: [Int] = []
        var currencies = Set<String>()

        for (offset, fields) in table.dropFirst().enumerated() {
            let sourceLine = offset + 2
            let values = fields + Array(repeating: "", count: max(0, header.count - fields.count))
            guard values.contains(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else { continue }

            let currency = value(at: currencyIndex, in: values).uppercased()
            currencies.insert(currency)
            guard
                let date = parseDate(value(at: dateIndex, in: values)),
                let amount = parseDecimal(value(at: amountIndex, in: values)),
                !currency.isEmpty
            else {
                invalidLineNumbers.append(sourceLine)
                continue
            }

            rows.append(Row(
                date: date,
                amount: amount,
                currency: currency,
                account: value(at: accountIndex, in: values),
                article: value(at: articleIndex, in: values),
                group: groupIndex.map { value(at: $0, in: values) } ?? "",
                comment: commentIndex.map { value(at: $0, in: values) } ?? "",
                sourceLine: sourceLine
            ))
        }

        let nonEmptyCurrencies = currencies.filter { !$0.isEmpty }
        let unsupported = nonEmptyCurrencies.filter { $0 != "RUB" }
        if !unsupported.isEmpty {
            throw MoneyOKImportError.unsupportedCurrency(Set(unsupported))
        }
        if rows.isEmpty {
            if !invalidLineNumbers.isEmpty { throw MoneyOKImportError.invalidRows(invalidLineNumbers) }
            throw MoneyOKImportError.emptyFile
        }

        let latestDate = rows.map(\.date).max() ?? Date()
        let bookName = uniqueBookName(base: "MoneyOK — импорт \(formatBookDate(latestDate))", context: context)
        let book = Book.create(in: context, name: bookName, icon: "tray.and.arrow.down", type: .personal, currency: "RUB")
        let owner = Member.create(
            in: context,
            name: LocalizationManager.localized("common.me"),
            book: book,
            role: .owner
        )

        var accountCache: [String: Account] = [:]
        var categoryCache: [String: Category] = [:]
        var createdAccounts = 0
        var createdCategories = 0
        var importedTransactions = 0
        var importedTransfers = 0
        var appliedBalances = 0
        var skippedRows = invalidLineNumbers.count

        for row in rows {
            let rawAccount = row.account.isEmpty ? "Без счёта" : row.account
            let accountName = rawAccount == "/удален/" ? "Удалённый счёт" : rawAccount
            let account: Account
            if let existing = accountCache[accountName] {
                account = existing
            } else {
                let type: AccountType = accountName.localizedCaseInsensitiveContains("кредит") ? .credit : .cash
                account = Account.create(in: context, name: accountName, book: book, type: type)
                accountCache[accountName] = account
                createdAccounts += 1
            }

            if row.article == "Остаток на счете" || row.article == "Остаток на счёте" {
                account.balance = NSDecimalNumber(decimal: row.amount)
                appliedBalances += 1
                continue
            }

            guard !row.article.isEmpty else {
                skippedRows += 1
                continue
            }

            let transactionType: TransactionType = row.article == "Перевод"
                ? .transfer
                : (row.amount < 0 ? .expense : .income)
            let categoryType: CategoryType = transactionType == .income ? .income : .expense
            let parentName = transactionType == .transfer ? "" : row.group
            let categoryKey = "\(categoryType.rawValue)|\(parentName)|\(row.article)"
            let category: Category

            if let existing = categoryCache[categoryKey] {
                category = existing
            } else {
                var parent: Category?
                if !parentName.isEmpty {
                    let parentKey = "\(categoryType.rawValue)||\(parentName)"
                    if let existingParent = categoryCache[parentKey] {
                        parent = existingParent
                    } else {
                        let newParent = Category.create(
                            in: context,
                            name: parentName == "/удален/" ? "Удалённая группа" : parentName,
                            icon: "folder",
                            categoryType: categoryType,
                            book: book,
                            sortOrder: Int32(createdCategories)
                        )
                        categoryCache[parentKey] = newParent
                        parent = newParent
                        createdCategories += 1
                    }
                }

                let newCategory = Category.create(
                    in: context,
                    name: row.article,
                    icon: transactionType == .transfer ? "arrow.left.arrow.right" : (categoryType == .income ? "arrow.down.circle" : "tag"),
                    categoryType: categoryType,
                    book: book,
                    parentId: parent?.id,
                    sortOrder: Int32(createdCategories)
                )
                categoryCache[categoryKey] = newCategory
                category = newCategory
                createdCategories += 1
            }

            var tags = ["счёт:\(rawAccount)"]
            if !row.group.isEmpty { tags.append("группа:\(row.group)") }
            if transactionType == .transfer, !row.group.isEmpty {
                tags.append("назначение:\(row.group)")
            }

            let note = row.comment.isEmpty ? nil : row.comment
            _ = Transaction.create(
                in: context,
                amount: row.amount < 0 ? -row.amount : row.amount,
                type: transactionType,
                category: category,
                book: book,
                member: owner,
                note: note,
                tags: tags,
                date: row.date
            )
            importedTransactions += 1
            if transactionType == .transfer { importedTransfers += 1 }
        }

        do {
            try context.save()
        } catch {
            throw MoneyOKImportError.saveFailed(error)
        }

        return MoneyOKImportSummary(
            book: book,
            importedTransactions: importedTransactions,
            importedTransfers: importedTransfers,
            appliedBalances: appliedBalances,
            createdAccounts: createdAccounts,
            createdCategories: createdCategories,
            skippedRows: skippedRows
        )
    }

    private static func parseDelimited(_ text: String, delimiter: Character) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var quoted = false
        var characters = Array(text)
        characters.append("\n")

        var index = 0
        while index < characters.count {
            let character = characters[index]
            if character == "\"" {
                if quoted && index + 1 < characters.count && characters[index + 1] == "\"" {
                    field.append("\"")
                    index += 2
                    continue
                }
                quoted.toggle()
            } else if character == delimiter && !quoted {
                row.append(field.trimmingCharacters(in: .whitespacesAndNewlines))
                field = ""
            } else if (character == "\n" || character == "\r") && !quoted {
                if character == "\r", index + 1 < characters.count, characters[index + 1] == "\n" {
                    index += 1
                }
                row.append(field.trimmingCharacters(in: .whitespacesAndNewlines))
                field = ""
                if row.contains(where: { !$0.isEmpty }) { rows.append(row) }
                row = []
            } else {
                field.append(character)
            }
            index += 1
        }
        return rows
    }

    private static func value(at index: Int, in values: [String]) -> String {
        guard values.indices.contains(index) else { return "" }
        return values[index].trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func normalize(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func index(of candidates: [String], in headers: [String]) -> Int? {
        headers.firstIndex { candidates.contains($0) }
    }

    private static func parseDate(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        for format in dateFormats {
            formatter.dateFormat = format
            if let date = formatter.date(from: value.trimmingCharacters(in: .whitespacesAndNewlines)) {
                return date
            }
        }
        return nil
    }

    private static func parseDecimal(_ value: String) -> Decimal? {
        var normalized = value
            .replacingOccurrences(of: "\u{00A0}", with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.contains(",") && normalized.contains(".") {
            if normalized.lastIndex(of: ",")! > normalized.lastIndex(of: ".")! {
                normalized = normalized.replacingOccurrences(of: ".", with: "")
                    .replacingOccurrences(of: ",", with: ".")
            } else {
                normalized = normalized.replacingOccurrences(of: ",", with: "")
            }
        } else {
            normalized = normalized.replacingOccurrences(of: ",", with: ".")
        }
        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
    }

    private static func formatBookDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
    }

    private static func uniqueBookName(base: String, context: NSManagedObjectContext) -> String {
        let request = NSFetchRequest<Book>(entityName: "Book")
        let names = ((try? context.fetch(request)) ?? []).map(\.name)
        guard names.contains(base) else { return base }
        var suffix = 2
        while names.contains("\(base) (\(suffix))") { suffix += 1 }
        return "\(base) (\(suffix))"
    }
}
