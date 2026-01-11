import Foundation
import Combine
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var symbolStore: SymbolStore
    @Published var settingsManager: SettingsManager
    @Published var priceManager: PriceManager

    @Published var showingAddSymbol = false
    @Published var editingSymbol: Symbol?
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()
    private let alertManager = AlertManager.shared

    init() {
        self.symbolStore = SymbolStore()
        self.settingsManager = SettingsManager()
        self.priceManager = PriceManager()

        setupBindings()
        startMonitoring()
    }

    var symbols: [Symbol] {
        symbolStore.symbols.sorted { $0.sortOrder < $1.sortOrder }
    }

    var cryptoSymbols: [Symbol] {
        symbolStore.cryptoSymbols
    }

    var stockSymbols: [Symbol] {
        symbolStore.stockSymbols
    }

    var settings: AppSettings {
        settingsManager.settings
    }

    var displaySymbols: [Symbol] {
        symbolStore.topSymbols(count: settings.menuBarDisplayCount)
    }

    var hasSymbols: Bool {
        !symbolStore.symbols.isEmpty
    }

    var isOffline: Bool {
        guard hasSymbols else { return false }

        // Check if we have any prices at all
        var hasPrices = false
        var hasNonStale = false

        for symbol in symbols {
            if let price = priceManager.price(for: symbol) {
                hasPrices = true
                if !price.isStale {
                    hasNonStale = true
                    break
                }
            }
        }

        // Only offline if we have prices but they're ALL stale
        // If no prices yet, we're loading, not offline
        return hasPrices && !hasNonStale
    }

    func price(for symbol: Symbol) -> PriceData? {
        priceManager.price(for: symbol)
    }

    func addSymbol(_ symbol: Symbol) {
        do {
            try symbolStore.add(symbol)
            updateMonitoring()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateSymbol(_ symbol: Symbol) {
        symbolStore.update(symbol)
    }

    func removeSymbol(_ symbol: Symbol) {
        symbolStore.remove(symbol: symbol)
        updateMonitoring()
    }

    func moveSymbols(from source: IndexSet, to destination: Int) {
        symbolStore.move(from: source, to: destination)
    }

    func updateSettings(_ newSettings: AppSettings) {
        settingsManager.update(newSettings)
        priceManager.updateSettings(newSettings)
        alertManager.updateSettings(newSettings)
    }

    func resetSettings() {
        settingsManager.resetToDefaults()
        priceManager.updateSettings(settings)
        alertManager.updateSettings(settings)
    }

    func openSymbolURL(_ symbol: Symbol) {
        guard let url = symbol.tradingURL(currency: settings.displayCurrency) else { return }
        NSWorkspace.shared.open(url)
    }

    private func setupBindings() {
        symbolStore.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        settingsManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        priceManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
                self?.checkAlerts()
            }
            .store(in: &cancellables)
    }

    private func startMonitoring() {
        priceManager.startMonitoring(
            cryptoSymbols: cryptoSymbols,
            stockSymbols: stockSymbols,
            settings: settings
        )
        alertManager.updateSettings(settings)
    }

    private func updateMonitoring() {
        priceManager.updateCryptoSymbols(cryptoSymbols)
        priceManager.updateStockSymbols(stockSymbols)
    }

    private func checkAlerts() {
        alertManager.checkAlerts(
            for: symbols,
            prices: priceManager.prices,
            settings: settings
        )
    }
}
