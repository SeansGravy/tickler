import Foundation
import Combine

@MainActor
final class PriceManager: ObservableObject {
    @Published private(set) var prices: [String: PriceData] = [:]
    @Published private(set) var coinbaseState: ConnectionState = .disconnected
    @Published private(set) var alpacaError: Error?

    private let coinbaseService = CoinbaseWebSocketService()
    private let alpacaService = AlpacaAPIService()
    private var cancellables = Set<AnyCancellable>()

    private var cryptoSymbols: [Symbol] = []
    private var stockSymbols: [Symbol] = []

    init() {
        setupBindings()
    }

    private func setupBindings() {
        Task {
            for await state in await coinbaseService.statePublisher.values {
                await MainActor.run {
                    self.coinbaseState = state
                }
            }
        }

        Task {
            for await update in await coinbaseService.pricePublisher.values {
                await MainActor.run {
                    self.handleCoinbaseUpdate(update)
                }
            }
        }

        alpacaService.pricePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                self?.handleAlpacaUpdate(update)
            }
            .store(in: &cancellables)

        alpacaService.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.alpacaError = error
            }
            .store(in: &cancellables)
    }

    func startMonitoring(cryptoSymbols: [Symbol], stockSymbols: [Symbol], settings: AppSettings) {
        self.cryptoSymbols = cryptoSymbols
        self.stockSymbols = stockSymbols

        // Start Coinbase WebSocket for crypto
        if settings.streamingEnabled && !cryptoSymbols.isEmpty {
            let productIds = cryptoSymbols.map { $0.productId }
            Task {
                await coinbaseService.connect(productIds: productIds)
            }
        }

        // Start Alpaca polling for stocks
        if settings.hasAlpacaCredentials && !stockSymbols.isEmpty {
            alpacaService.updateCredentials(
                apiKey: settings.alpacaAPIKey,
                secretKey: settings.alpacaAPISecret
            )
            let tickers = stockSymbols.map { $0.ticker }
            alpacaService.startPolling(symbols: tickers)
        }
    }

    func stopMonitoring() {
        Task {
            await coinbaseService.disconnect()
        }
        alpacaService.stopPolling()
    }

    func updateCryptoSymbols(_ symbols: [Symbol]) {
        self.cryptoSymbols = symbols
        let productIds = symbols.map { $0.productId }
        Task {
            await coinbaseService.updateSubscriptions(productIds: productIds)
        }
    }

    func updateStockSymbols(_ symbols: [Symbol]) {
        self.stockSymbols = symbols
        let tickers = symbols.map { $0.ticker }
        alpacaService.updateSymbols(tickers)
    }

    func updateSettings(_ settings: AppSettings) {
        alpacaService.updateCredentials(
            apiKey: settings.alpacaAPIKey,
            secretKey: settings.alpacaAPISecret
        )

        if settings.streamingEnabled {
            let productIds = cryptoSymbols.map { $0.productId }
            Task {
                await coinbaseService.connect(productIds: productIds)
            }
        } else {
            Task {
                await coinbaseService.disconnect()
            }
        }
    }

    func price(for symbol: Symbol) -> PriceData? {
        let key = symbol.type == .crypto ? symbol.productId : symbol.ticker
        return prices[key]
    }

    private func handleCoinbaseUpdate(_ update: (productId: String, price: Double, open24h: Double)) {
        let percentChange = ((update.price - update.open24h) / update.open24h) * 100
        let priceData = PriceData(
            price: update.price,
            percentChange24h: percentChange,
            lastUpdated: Date()
        )
        prices[update.productId] = priceData
    }

    private func handleAlpacaUpdate(_ update: (symbol: String, price: Double, prevClose: Double)) {
        let percentChange = ((update.price - update.prevClose) / update.prevClose) * 100
        let priceData = PriceData(
            price: update.price,
            percentChange24h: percentChange,
            lastUpdated: Date()
        )
        prices[update.symbol] = priceData
    }
}
