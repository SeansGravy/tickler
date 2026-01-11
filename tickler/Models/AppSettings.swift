import Foundation

enum StockRefreshInterval: Int, Codable, CaseIterable {
    case fifteenSeconds = 15
    case thirtySeconds = 30
    case sixtySeconds = 60
    case fiveMinutes = 300

    var displayName: String {
        switch self {
        case .fifteenSeconds: return "15 seconds"
        case .thirtySeconds: return "30 seconds"
        case .sixtySeconds: return "1 minute"
        case .fiveMinutes: return "5 minutes"
        }
    }
}

enum NotificationStyle: String, Codable, CaseIterable {
    case banner
    case sound
    case both

    var displayName: String {
        switch self {
        case .banner: return "Banner"
        case .sound: return "Sound"
        case .both: return "Both"
        }
    }
}

enum AlertCooldown: Int, Codable, CaseIterable {
    case fiveMinutes = 300
    case fifteenMinutes = 900
    case oneHour = 3600
    case fourHours = 14400

    var displayName: String {
        switch self {
        case .fiveMinutes: return "5 minutes"
        case .fifteenMinutes: return "15 minutes"
        case .oneHour: return "1 hour"
        case .fourHours: return "4 hours"
        }
    }
}

struct AppSettings: Codable, Equatable {
    // Display
    var menuBarDisplayCount: Int
    var showPercentChange: Bool
    var compactPrices: Bool
    var decimalPlaces: Int

    // Defaults
    var defaultCryptoExchange: Exchange
    var defaultStockBroker: Exchange

    // Data
    var streamingEnabled: Bool
    var stockRefreshInterval: StockRefreshInterval
    var pauseOnBattery: Bool

    // Alerts
    var alertsEnabled: Bool
    var notificationStyle: NotificationStyle
    var alertCooldown: AlertCooldown

    // System
    var launchAtLogin: Bool

    static let `default` = AppSettings(
        menuBarDisplayCount: 1,
        showPercentChange: true,
        compactPrices: true,
        decimalPlaces: 2,
        defaultCryptoExchange: .coinbase,
        defaultStockBroker: .yahoo,
        streamingEnabled: true,
        stockRefreshInterval: .sixtySeconds,
        pauseOnBattery: false,
        alertsEnabled: false,
        notificationStyle: .banner,
        alertCooldown: .oneHour,
        launchAtLogin: true
    )
}
