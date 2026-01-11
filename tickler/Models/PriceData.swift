import Foundation

struct PriceData: Equatable {
    let price: Double
    let percentChange24h: Double
    let lastUpdated: Date

    var isStale: Bool {
        Date().timeIntervalSince(lastUpdated) > 60
    }
}
