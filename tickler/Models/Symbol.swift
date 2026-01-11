import Foundation

enum SymbolType: String, Codable, CaseIterable {
    case crypto
    case stock
}

enum Exchange: String, Codable, CaseIterable {
    case coinbase
    case kraken
    case alpaca

    var displayName: String {
        switch self {
        case .coinbase: return "Coinbase"
        case .kraken: return "Kraken"
        case .alpaca: return "Alpaca"
        }
    }

    static var cryptoExchanges: [Exchange] {
        [.coinbase, .kraken]
    }

    static var stockExchanges: [Exchange] {
        [.alpaca]
    }

    func priceURL(for ticker: String) -> URL? {
        switch self {
        case .coinbase:
            return URL(string: "https://www.coinbase.com/price/\(ticker.lowercased())")
        case .kraken:
            return URL(string: "https://www.kraken.com/prices/\(ticker.lowercased())")
        case .alpaca:
            return URL(string: "https://app.alpaca.markets/trade/\(ticker.uppercased())")
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

    init(
        id: UUID = UUID(),
        ticker: String,
        displayName: String,
        type: SymbolType,
        exchange: Exchange,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.ticker = ticker.uppercased()
        self.displayName = displayName
        self.type = type
        self.exchange = exchange
        self.sortOrder = sortOrder
    }

    var productId: String {
        switch type {
        case .crypto:
            return "\(ticker)-USD"
        case .stock:
            return ticker
        }
    }
}
