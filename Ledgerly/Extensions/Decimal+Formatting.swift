import Foundation

extension Decimal {
    var currencyString: String {
        let formatter = NumberFormatter()
        formatter.locale = Language.current.locale
        formatter.numberStyle = .currency
        formatter.currencyCode = MoneyFormatting.currencyCode
        formatter.maximumFractionDigits = 2
        return formatter.string(from: self as NSDecimalNumber) ?? "0,00 \(MoneyFormatting.symbol)"
    }

    var compactString: String {
        let absValue = abs(NSDecimalNumber(decimal: self).doubleValue)
        if absValue >= 1_000_000 {
            return String(format: "%.1fM", absValue / 1_000_000)
        } else if absValue >= 10_000 {
            return String(format: "%.1fW", absValue / 10_000)
        } else if absValue >= 1_000 {
            return String(format: "%.1fK", absValue / 1_000)
        }
        return String(format: "%.2f", NSDecimalNumber(decimal: self).doubleValue)
    }

    var percentageString: String {
        let value = NSDecimalNumber(decimal: self).doubleValue
        guard value.isFinite else { return "0.0%" }
        return String(format: "%.1f%%", value * 100)
    }
}

/// The existing application uses one display currency; changing it does not convert amounts.
enum MoneyFormatting {
    static var currencyCode: String {
        UserDefaults.standard.string(forKey: "currency") ?? "RUB"
    }

    static var symbol: String {
        switch currencyCode {
        case "RUB": return "₽"
        case "USD": return "$"
        case "EUR": return "€"
        case "JPY", "CNY": return "¥"
        default: return currencyCode
        }
    }
}
