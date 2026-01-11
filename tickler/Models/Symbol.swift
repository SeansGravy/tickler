import Foundation

enum SymbolType: String, Codable, CaseIterable {
    case crypto
    case stock
}

enum Exchange: String, Codable, CaseIterable {
    // Crypto exchanges
    case coinbase
    case kraken
    // Stock brokers
    case yahoo
    case robinhood
    case tradingview

    var displayName: String {
        switch self {
        case .coinbase: return "Coinbase"
        case .kraken: return "Kraken"
        case .yahoo: return "Yahoo Finance"
        case .robinhood: return "Robinhood"
        case .tradingview: return "TradingView"
        }
    }

    static var cryptoExchanges: [Exchange] {
        [.coinbase, .kraken]
    }

    static var stockBrokers: [Exchange] {
        [.yahoo, .robinhood, .tradingview]
    }

    func priceURL(for ticker: String, currency: Currency = .usd) -> URL? {
        switch self {
        case .coinbase:
            return URL(string: "https://www.coinbase.com/advanced-trade/spot/\(ticker.uppercased())-\(currency.coinbaseCode)")
        case .kraken:
            return URL(string: "https://www.kraken.com/trade/\(ticker.uppercased())-\(currency.coinbaseCode)")
        case .yahoo:
            return URL(string: "https://finance.yahoo.com/quote/\(ticker.uppercased())")
        case .robinhood:
            return URL(string: "https://robinhood.com/stocks/\(ticker.uppercased())")
        case .tradingview:
            return URL(string: "https://www.tradingview.com/symbols/\(ticker.uppercased())")
        }
    }
}

enum TradingPlatform: String, Codable, CaseIterable {
    case coinbase
    case kraken
    case yahoo
    case robinhood
    case tradingview

    var displayName: String {
        switch self {
        case .coinbase: return "Coinbase"
        case .kraken: return "Kraken"
        case .yahoo: return "Yahoo Finance"
        case .robinhood: return "Robinhood"
        case .tradingview: return "TradingView"
        }
    }

    func url(for ticker: String, currency: Currency) -> URL {
        switch self {
        case .coinbase:
            return URL(string: "https://www.coinbase.com/advanced-trade/spot/\(ticker.uppercased())-\(currency.coinbaseCode)")!
        case .kraken:
            return URL(string: "https://www.kraken.com/trade/\(ticker.uppercased())-\(currency.coinbaseCode)")!
        case .yahoo:
            return URL(string: "https://finance.yahoo.com/quote/\(ticker.uppercased())")!
        case .robinhood:
            return URL(string: "https://robinhood.com/stocks/\(ticker.uppercased())")!
        case .tradingview:
            return URL(string: "https://www.tradingview.com/symbols/\(ticker.uppercased())")!
        }
    }

    static func from(exchange: Exchange) -> TradingPlatform {
        switch exchange {
        case .coinbase: return .coinbase
        case .kraken: return .kraken
        case .yahoo: return .yahoo
        case .robinhood: return .robinhood
        case .tradingview: return .tradingview
        }
    }
}

struct Symbol: Identifiable, Codable, Equatable {
    let id: UUID
    var ticker: String
    var displayName: String
    var type: SymbolType
    var exchange: Exchange
    var sortOrder: Int
    var group: String?

    // Alerts
    var alertEnabled: Bool
    var alertAbovePrice: Double?
    var alertBelowPrice: Double?
    var alertPercentChange: Double?

    // Per-symbol override
    var tradingPlatformOverride: TradingPlatform?

    init(
        id: UUID = UUID(),
        ticker: String,
        displayName: String,
        type: SymbolType,
        exchange: Exchange,
        sortOrder: Int = 0,
        group: String? = nil,
        alertEnabled: Bool = false,
        alertAbovePrice: Double? = nil,
        alertBelowPrice: Double? = nil,
        alertPercentChange: Double? = nil,
        tradingPlatformOverride: TradingPlatform? = nil
    ) {
        self.id = id
        self.ticker = ticker.uppercased()
        self.displayName = displayName
        self.type = type
        self.exchange = exchange
        self.sortOrder = sortOrder
        self.group = group
        self.alertEnabled = alertEnabled
        self.alertAbovePrice = alertAbovePrice
        self.alertBelowPrice = alertBelowPrice
        self.alertPercentChange = alertPercentChange
        self.tradingPlatformOverride = tradingPlatformOverride
    }

    func productId(for currency: Currency) -> String {
        switch type {
        case .crypto:
            return "\(ticker)-\(currency.coinbaseCode)"
        case .stock:
            return ticker
        }
    }

    var productId: String {
        productId(for: .usd)
    }

    var hasActiveAlerts: Bool {
        alertEnabled && (alertAbovePrice != nil || alertBelowPrice != nil || alertPercentChange != nil)
    }

    func tradingURL(currency: Currency) -> URL? {
        if let override = tradingPlatformOverride {
            return override.url(for: ticker, currency: currency)
        }
        return exchange.priceURL(for: ticker, currency: currency)
    }
}
