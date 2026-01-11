import Foundation
import UserNotifications

@MainActor
final class AlertManager: ObservableObject {
    static let shared = AlertManager()

    private var lastAlertTime: [UUID: Date] = [:]
    private var cooldownInterval: TimeInterval = 3600

    private init() {
        requestPermission()
    }

    func checkAlerts(symbol: Symbol, price: PriceData, settings: AppSettings) {
        guard symbol.alertEnabled else { return }
        guard canAlert(for: symbol.id) else { return }

        var triggered = false
        var message = ""

        if let above = symbol.alertAbovePrice, price.price >= above {
            triggered = true
            message = "\(symbol.ticker) above \(formatPrice(above)): now \(formatPrice(price.price))"
        }

        if let below = symbol.alertBelowPrice, price.price <= below {
            triggered = true
            message = "\(symbol.ticker) below \(formatPrice(below)): now \(formatPrice(price.price))"
        }

        if let pct = symbol.alertPercentChange, abs(price.percentChange24h) >= pct {
            triggered = true
            let direction = price.percentChange24h >= 0 ? "up" : "down"
            message = "\(symbol.ticker) \(direction) \(String(format: "%.1f", abs(price.percentChange24h)))%"
        }

        if triggered {
            sendNotification(title: "Tickler Alert", body: message, settings: settings)
            lastAlertTime[symbol.id] = Date()
        }
    }

    func checkAlerts(for symbols: [Symbol], prices: [String: PriceData], settings: AppSettings) {
        guard settings.alertsEnabled else { return }

        for symbol in symbols where symbol.alertEnabled {
            let key = symbol.type == .crypto ? symbol.productId(for: settings.displayCurrency) : symbol.ticker
            if let price = prices[key] {
                checkAlerts(symbol: symbol, price: price, settings: settings)
            }
        }
    }

    private func canAlert(for symbolId: UUID) -> Bool {
        guard let last = lastAlertTime[symbolId] else { return true }
        return Date().timeIntervalSince(last) >= cooldownInterval
    }

    private func sendNotification(title: String, body: String, settings: AppSettings) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body

        switch settings.notificationStyle {
        case .sound:
            content.sound = .default
        case .both:
            content.sound = .default
        case .banner:
            break
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                AppLogger.log("Failed to send notification: \(error)", category: "Alerts")
            }
        }
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                AppLogger.log("Notification permission error: \(error)", category: "Alerts")
            } else if granted {
                AppLogger.log("Notification permission granted", category: "Alerts")
            }
        }
    }

    func updateSettings(_ settings: AppSettings) {
        cooldownInterval = TimeInterval(settings.alertCooldown.rawValue)
    }

    private func formatPrice(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: value)) ?? "$\(value)"
    }
}
