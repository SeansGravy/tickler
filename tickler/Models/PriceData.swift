import Foundation

struct PriceData: Equatable {
    let price: Double
    let percentChange24h: Double
    let lastUpdated: Date

    var isStale: Bool {
        Date().timeIntervalSince(lastUpdated) > 60
    }
}

// MARK: - Coinbase WebSocket DTOs

struct CoinbaseSubscription: Encodable {
    let type = "subscribe"
    let channels: [Channel]

    struct Channel: Encodable {
        let name = "ticker"
        let productIds: [String]

        enum CodingKeys: String, CodingKey {
            case name
            case productIds = "product_ids"
        }
    }

    init(productIds: [String]) {
        self.channels = [Channel(productIds: productIds)]
    }
}

struct CoinbaseUnsubscription: Encodable {
    let type = "unsubscribe"
    let channels: [Channel]

    struct Channel: Encodable {
        let name = "ticker"
        let productIds: [String]

        enum CodingKeys: String, CodingKey {
            case name
            case productIds = "product_ids"
        }
    }

    init(productIds: [String]) {
        self.channels = [Channel(productIds: productIds)]
    }
}

struct CoinbaseMessage: Decodable {
    let type: String
    let productId: String?
    let price: String?
    let open24h: String?
    let time: String?

    enum CodingKeys: String, CodingKey {
        case type
        case productId = "product_id"
        case price
        case open24h = "open_24h"
        case time
    }
}

// MARK: - Alpaca REST DTOs

struct AlpacaQuoteResponse: Decodable {
    let quote: AlpacaQuote

    struct AlpacaQuote: Decodable {
        let ap: Double  // ask price
        let bp: Double  // bid price
        let t: String   // timestamp

        var midPrice: Double {
            (ap + bp) / 2
        }
    }
}

struct AlpacaBarResponse: Decodable {
    let bar: AlpacaBar?
    let bars: [String: AlpacaBar]?

    struct AlpacaBar: Decodable {
        let o: Double  // open
        let c: Double  // close
        let h: Double  // high
        let l: Double  // low
        let t: String  // timestamp
    }
}

struct AlpacaSnapshotResponse: Decodable {
    let latestTrade: LatestTrade?
    let prevDailyBar: DailyBar?

    enum CodingKeys: String, CodingKey {
        case latestTrade
        case prevDailyBar
    }

    struct LatestTrade: Decodable {
        let p: Double  // price
        let t: String  // timestamp
    }

    struct DailyBar: Decodable {
        let c: Double  // close
    }
}
