import Foundation
import Combine

@MainActor
final class SettingsManager: ObservableObject {
    @Published private(set) var settings: AppSettings

    private let userDefaults: UserDefaults
    private let settingsKey = "ticklerSettings"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.settings = Self.load(from: userDefaults, key: settingsKey)
    }

    private static func load(from userDefaults: UserDefaults, key: String) -> AppSettings {
        guard let data = userDefaults.data(forKey: key),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return .default
        }
        return settings
    }

    func update(_ settings: AppSettings) {
        self.settings = settings
        save()
        syncLaunchAtLogin()
    }

    func updateMenuBarDisplayCount(_ count: Int) {
        var updated = settings
        updated.menuBarDisplayCount = max(1, min(10, count))
        update(updated)
    }

    func updateDefaultCryptoExchange(_ exchange: Exchange) {
        var updated = settings
        updated.defaultCryptoExchange = exchange
        update(updated)
    }

    func updateDefaultStockBroker(_ exchange: Exchange) {
        var updated = settings
        updated.defaultStockBroker = exchange
        update(updated)
    }

    func updateLaunchAtLogin(_ enabled: Bool) {
        var updated = settings
        updated.launchAtLogin = enabled
        update(updated)
    }

    func updateStreamingEnabled(_ enabled: Bool) {
        var updated = settings
        updated.streamingEnabled = enabled
        update(updated)
    }

    func updateAlpacaCredentials(apiKey: String, secret: String) {
        var updated = settings
        updated.alpacaAPIKey = apiKey
        updated.alpacaAPISecret = secret
        update(updated)
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        userDefaults.set(data, forKey: settingsKey)
    }

    private func syncLaunchAtLogin() {
        do {
            try LaunchAtLoginManager.setEnabled(settings.launchAtLogin)
        } catch {
            print("Failed to update launch at login: \(error)")
        }
    }
}
