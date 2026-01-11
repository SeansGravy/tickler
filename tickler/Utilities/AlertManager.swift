import Foundation
import UserNotifications
import AppKit

@MainActor
final class AlertManager: ObservableObject {
    private var lastAlertTimes: [UUID: Date] = [:]
    private var cooldownInterval: TimeInterval = 3600  // 1 hour default
    private var notificationStyle: NotificationStyle = .banner

    static let shared = AlertManager()

    private init() {
        requestNotificationPermission()
    }

    func updateSettings(_ settings: AppSettings) {
        cooldownInterval = TimeInterval(settings.alertCooldown.rawValue)
        notificationStyle = settings.notificationStyle
    }

    func checkAlerts(for symbols: [Symbol], prices: [String: PriceData], settings: AppSettings) {
        guard settings.alertsEnabled else { return }

        for symbol in symbols {
            guard symbol.alertEnabled else { continue }

            let key = symbol.type == .crypto ? symbol.productId : symbol.ticker
            guard let priceData = prices[key] else { continue }

            if shouldTriggerAlert(for: symbol, price: priceData) {
                triggerAlert(for: symbol, price: priceData)
            }
        }
    }

    private func shouldTriggerAlert(for symbol: Symbol, price: PriceData) -> Bool {
        // Check cooldown
        if let lastAlert = lastAlertTimes[symbol.id] {
            if Date().timeIntervalSince(lastAlert) < cooldownInterval {
                return false
            }
        }

        // Check price thresholds
        if let abovePrice = symbol.alertAbovePrice, price.price >= abovePrice {
            return true
        }

        if let belowPrice = symbol.alertBelowPrice, price.price <= belowPrice {
            return true
        }

        // Check percent change threshold
        if let percentThreshold = symbol.alertPercentChange {
            if abs(price.percentChange24h) >= percentThreshold {
                return true
            }
        }

        return false
    }

    private func triggerAlert(for symbol: Symbol, price: PriceData) {
        lastAlertTimes[symbol.id] = Date()

        let title = "\(symbol.ticker) Alert"
        var body = "\(symbol.displayName): \(PriceFormatter.formatFull(price.price))"

        if let abovePrice = symbol.alertAbovePrice, price.price >= abovePrice {
            body += " (above $\(String(format: "%.2f", abovePrice)))"
        } else if let belowPrice = symbol.alertBelowPrice, price.price <= belowPrice {
            body += " (below $\(String(format: "%.2f", belowPrice)))"
        } else if let percentThreshold = symbol.alertPercentChange {
            body += " (\(PriceFormatter.formatPercentChange(price.percentChange24h)) threshold: ±\(String(format: "%.1f", percentThreshold))%)"
        }

        sendNotification(title: title, body: body)
    }

    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body

        switch notificationStyle {
        case .sound, .both:
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
                print("Failed to send notification: \(error)")
            }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    func clearAlertHistory(for symbolId: UUID) {
        lastAlertTimes.removeValue(forKey: symbolId)
    }

    func clearAllAlertHistory() {
        lastAlertTimes.removeAll()
    }
}
