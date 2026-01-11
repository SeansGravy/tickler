import Foundation

struct PriceFormatter {
    static func formatCompact(_ value: Double) -> String {
        let absValue = abs(value)
        let formatted: String

        switch absValue {
        case 1_000_000...:
            formatted = String(format: "$%.1fM", absValue / 1_000_000)
        case 100_000..<1_000_000:
            formatted = String(format: "$%.1fk", absValue / 1_000)
        case 1_000..<100_000:
            formatted = String(format: "$%.1fk", absValue / 1_000)
        case 1..<1_000:
            formatted = String(format: "$%.2f", absValue)
        default:
            formatted = String(format: "$%.4f", absValue)
        }

        return value < 0 ? "-\(formatted)" : formatted
    }

    static func formatFull(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = value < 1 ? 4 : 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    static func formatPrice(_ value: Double, compact: Bool, decimalPlaces: Int = 2) -> String {
        if compact {
            return formatCompact(value)
        } else {
            return formatWithDecimals(value, places: decimalPlaces)
        }
    }

    static func formatWithDecimals(_ value: Double, places: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = places
        formatter.maximumFractionDigits = places
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    static func formatPercentChange(_ value: Double) -> String {
        let arrow = value >= 0 ? "\u{25B2}" : "\u{25BC}"  // ▲ or ▼
        return String(format: "%@%.1f%%", arrow, abs(value))
    }

    static func formatMenuBarItem(ticker: String, price: Double, percentChange: Double, settings: AppSettings) -> String {
        let priceStr = settings.compactPrices ? formatCompact(price) : formatWithDecimals(price, places: settings.decimalPlaces)

        if settings.showPercentChange {
            let changeStr = formatPercentChange(percentChange)
            return "\(ticker) \(priceStr) \(changeStr)"
        } else {
            return "\(ticker) \(priceStr)"
        }
    }
}
