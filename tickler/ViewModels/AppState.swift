import Foundation
import Combine
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var symbolStore: SymbolStore
    @Published var settingsManager: SettingsManager
    @Published var priceManager: PriceManager

    @Published var showingSettings = false
    @Published var showingSymbolList = false
    @Published var showingAddSymbol = false
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()

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

        // Check if all prices are stale
        for symbol in symbols {
            if let price = priceManager.price(for: symbol), !price.isStale {
                return false
            }
        }
        return true
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
    }

    func openSymbolURL(_ symbol: Symbol) {
        guard let url = symbol.exchange.priceURL(for: symbol.ticker) else { return }
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
            }
            .store(in: &cancellables)
    }

    private func startMonitoring() {
        priceManager.startMonitoring(
            cryptoSymbols: cryptoSymbols,
            stockSymbols: stockSymbols,
            settings: settings
        )
    }

    private func updateMonitoring() {
        priceManager.updateCryptoSymbols(cryptoSymbols)
        priceManager.updateStockSymbols(stockSymbols)
    }
}
