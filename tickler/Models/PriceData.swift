import Foundation

struct PriceData: Equatable {
    let price: Double
    let percentChange24h: Double
    let high24h: Double?
    let low24h: Double?
    let volume24h: Double?
    let lastUpdated: Date

    init(
        price: Double,
        percentChange24h: Double,
        high24h: Double? = nil,
        low24h: Double? = nil,
        volume24h: Double? = nil,
        lastUpdated: Date = Date()
    ) {
        self.price = price
        self.percentChange24h = percentChange24h
        self.high24h = high24h
        self.low24h = low24h
        self.volume24h = volume24h
        self.lastUpdated = lastUpdated
    }

    var isStale: Bool {
        Date().timeIntervalSince(lastUpdated) > 60
    }
}
