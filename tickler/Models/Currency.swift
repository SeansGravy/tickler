import Foundation

enum Currency: String, Codable, CaseIterable {
    case usd, eur, gbp, jpy, cad, aud, chf, cny

    var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        case .jpy: return "¥"
        case .cad: return "C$"
        case .aud: return "A$"
        case .chf: return "CHF "
        case .cny: return "¥"
        }
    }

    var displayName: String {
        switch self {
        case .usd: return "USD ($)"
        case .eur: return "EUR (€)"
        case .gbp: return "GBP (£)"
        case .jpy: return "JPY (¥)"
        case .cad: return "CAD (C$)"
        case .aud: return "AUD (A$)"
        case .chf: return "CHF"
        case .cny: return "CNY (¥)"
        }
    }

    var coinbaseCode: String {
        rawValue.uppercased()
    }
}

enum ColorTheme: String, Codable, CaseIterable {
    case greenRed
    case blueOrange
    case monochrome

    var displayName: String {
        switch self {
        case .greenRed: return "Green / Red"
        case .blueOrange: return "Blue / Orange"
        case .monochrome: return "Monochrome"
        }
    }

    var positiveColor: String {
        switch self {
        case .greenRed: return "green"
        case .blueOrange: return "blue"
        case .monochrome: return "primary"
        }
    }

    var negativeColor: String {
        switch self {
        case .greenRed: return "red"
        case .blueOrange: return "orange"
        case .monochrome: return "primary"
        }
    }
}
