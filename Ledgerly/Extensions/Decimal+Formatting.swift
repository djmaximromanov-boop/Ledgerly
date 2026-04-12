import Foundation

extension Decimal {
    var currencyString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CNY"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: self as NSDecimalNumber) ?? "¥0.00"
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
