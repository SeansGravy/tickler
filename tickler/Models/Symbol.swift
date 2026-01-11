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

    func priceURL(for ticker: String) -> URL? {
        switch self {
        case .coinbase:
            return URL(string: "https://www.coinbase.com/advanced-trade/spot/\(ticker.uppercased())-USD")
        case .kraken:
            return URL(string: "https://www.kraken.com/trade/\(ticker.uppercased())-USD")
        case .yahoo:
            return URL(string: "https://finance.yahoo.com/quote/\(ticker.uppercased())")
        case .robinhood:
            return URL(string: "https://robinhood.com/stocks/\(ticker.uppercased())")
        case .tradingview:
            return URL(string: "https://www.tradingview.com/symbols/\(ticker.uppercased())")
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

    // Alert settings
    var alertEnabled: Bool
    var alertAbovePrice: Double?
    var alertBelowPrice: Double?
    var alertPercentChange: Double?

    init(
        id: UUID = UUID(),
        ticker: String,
        displayName: String,
        type: SymbolType,
        exchange: Exchange,
        sortOrder: Int = 0,
        alertEnabled: Bool = false,
        alertAbovePrice: Double? = nil,
        alertBelowPrice: Double? = nil,
        alertPercentChange: Double? = nil
    ) {
        self.id = id
        self.ticker = ticker.uppercased()
        self.displayName = displayName
        self.type = type
        self.exchange = exchange
        self.sortOrder = sortOrder
        self.alertEnabled = alertEnabled
        self.alertAbovePrice = alertAbovePrice
        self.alertBelowPrice = alertBelowPrice
        self.alertPercentChange = alertPercentChange
    }

    var productId: String {
        switch type {
        case .crypto:
            return "\(ticker)-USD"
        case .stock:
            return ticker
        }
    }

    var hasActiveAlerts: Bool {
        alertEnabled && (alertAbovePrice != nil || alertBelowPrice != nil || alertPercentChange != nil)
    }
}
