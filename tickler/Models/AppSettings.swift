import Foundation

struct AppSettings: Codable, Equatable {
    var menuBarDisplayCount: Int
    var defaultCryptoExchange: Exchange
    var defaultStockBroker: Exchange
    var launchAtLogin: Bool
    var streamingEnabled: Bool
    var alpacaAPIKey: String
    var alpacaAPISecret: String

    static let `default` = AppSettings(
        menuBarDisplayCount: 1,
        defaultCryptoExchange: .coinbase,
        defaultStockBroker: .alpaca,
        launchAtLogin: true,
        streamingEnabled: true,
        alpacaAPIKey: "",
        alpacaAPISecret: ""
    )

    var hasAlpacaCredentials: Bool {
        !alpacaAPIKey.isEmpty && !alpacaAPISecret.isEmpty
    }
}
