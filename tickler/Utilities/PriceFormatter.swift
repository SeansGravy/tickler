import Foundation
import SwiftUI

struct PriceFormatter {
    // Main formatting function with currency and decimals
    static func format(
        _ value: Double,
        currency: Currency,
        compact: Bool,
        decimals: Int
    ) -> String {
        let symbol = currency.symbol

        if compact {
            let absValue = abs(value)
            switch absValue {
            case 1_000_000_000...:
                return "\(symbol)\(String(format: "%.\(min(decimals, 2))f", value / 1_000_000_000))B"
            case 1_000_000...:
                return "\(symbol)\(String(format: "%.\(min(decimals, 2))f", value / 1_000_000))M"
            case 1_000...:
                return "\(symbol)\(String(format: "%.\(min(decimals, 2))f", value / 1_000))k"
            default:
                return "\(symbol)\(String(format: "%.\(decimals)f", value))"
            }
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = decimals
            formatter.maximumFractionDigits = decimals
            return "\(symbol)\(formatter.string(from: NSNumber(value: value)) ?? String(format: "%.\(decimals)f", value))"
        }
    }

    // Legacy functions for backward compatibility
    static func formatCompact(_ value: Double) -> String {
        format(value, currency: .usd, compact: true, decimals: 2)
    }

    static func formatWithDecimals(_ value: Double, places: Int) -> String {
        format(value, currency: .usd, compact: false, decimals: places)
    }

    static func formatFull(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = value < 1 ? 6 : 2
        return formatter.string(from: NSNumber(value: value)) ?? "$\(value)"
    }

    static func formatPercentChange(_ value: Double) -> String {
        let arrow = value >= 0 ? "▲" : "▼"
        return "\(arrow)\(String(format: "%.2f", abs(value)))%"
    }

    // Color helpers based on theme
    static func changeColor(for value: Double, theme: ColorTheme) -> Color {
        if value >= 0 {
            switch theme {
            case .greenRed: return .green
            case .blueOrange: return .blue
            case .monochrome: return .primary
            }
        } else {
            switch theme {
            case .greenRed: return .red
            case .blueOrange: return .orange
            case .monochrome: return .primary
            }
        }
    }
}
