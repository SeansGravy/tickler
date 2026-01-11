import Foundation
import Combine

@MainActor
final class PriceManager: ObservableObject {
    @Published private(set) var prices: [String: PriceData] = [:]
    @Published private(set) var coinbaseState: ConnectionState = .disconnected
    @Published private(set) var yahooError: Error?

    private let coinbaseService = CoinbaseWebSocketService()
    private let yahooService = YahooFinanceService()
    private var cancellables = Set<AnyCancellable>()
    private var coinbaseTasks: [Task<Void, Never>] = []

    private var cryptoSymbols: [Symbol] = []
    private var stockSymbols: [Symbol] = []

    init() {
        AppLogger.log("PriceManager init", category: "PriceManager")
        setupYahooBindings()
    }

    private func setupYahooBindings() {
        yahooService.pricePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                AppLogger.log("Yahoo update: \(update.symbol) = $\(update.price)", category: "Yahoo")
                self?.handleYahooUpdate(update)
            }
            .store(in: &cancellables)

        yahooService.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                AppLogger.log("Yahoo error: \(error)", category: "Yahoo")
                self?.yahooError = error
            }
            .store(in: &cancellables)
    }

    private func setupCoinbaseBindings() {
        AppLogger.log("Setting up Coinbase bindings", category: "Coinbase")

        // Cancel any existing tasks
        coinbaseTasks.forEach { $0.cancel() }
        coinbaseTasks.removeAll()

        // State updates
        let stateTask = Task { [weak self] in
            guard let self = self else { return }
            for await state in await coinbaseService.statePublisher.values {
                await MainActor.run {
                    AppLogger.log("Coinbase state: \(state)", category: "Coinbase")
                    self.coinbaseState = state
                }
            }
        }
        coinbaseTasks.append(stateTask)

        // Price updates
        let priceTask = Task { [weak self] in
            guard let self = self else { return }
            for await update in await coinbaseService.pricePublisher.values {
                await MainActor.run {
                    AppLogger.log("Coinbase price: \(update.productId) = $\(update.price)", category: "Coinbase")
                    self.handleCoinbaseUpdate(update)
                }
            }
        }
        coinbaseTasks.append(priceTask)
    }

    func startMonitoring(cryptoSymbols: [Symbol], stockSymbols: [Symbol], settings: AppSettings) {
        self.cryptoSymbols = cryptoSymbols
        self.stockSymbols = stockSymbols

        AppLogger.log("Starting monitoring", category: "PriceManager")
        AppLogger.log("Crypto symbols: \(cryptoSymbols.map { $0.ticker })", category: "PriceManager")
        AppLogger.log("Stock symbols: \(stockSymbols.map { $0.ticker })", category: "PriceManager")
        AppLogger.log("Streaming enabled: \(settings.streamingEnabled)", category: "PriceManager")

        // Start Coinbase WebSocket for crypto
        if settings.streamingEnabled && !cryptoSymbols.isEmpty {
            let productIds = cryptoSymbols.map { $0.productId }
            AppLogger.log("Connecting to Coinbase with products: \(productIds)", category: "Coinbase")

            // Setup bindings before connecting
            setupCoinbaseBindings()

            Task {
                await coinbaseService.connect(productIds: productIds)
            }
        } else {
            AppLogger.log("Skipping Coinbase: streaming=\(settings.streamingEnabled), cryptoCount=\(cryptoSymbols.count)", category: "Coinbase")
        }

        // Start Yahoo Finance polling for stocks
        if !stockSymbols.isEmpty {
            let tickers = stockSymbols.map { $0.ticker }
            AppLogger.log("Starting Yahoo polling for: \(tickers)", category: "Yahoo")
            yahooService.startPolling(
                symbols: tickers,
                interval: TimeInterval(settings.stockRefreshInterval.rawValue)
            )
        }
    }

    func stopMonitoring() {
        coinbaseTasks.forEach { $0.cancel() }
        coinbaseTasks.removeAll()
        Task {
            await coinbaseService.disconnect()
        }
        yahooService.stopPolling()
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
        yahooService.updateSymbols(tickers)
    }

    func updateSettings(_ settings: AppSettings) {
        yahooService.updateInterval(TimeInterval(settings.stockRefreshInterval.rawValue))

        if settings.streamingEnabled {
            let productIds = cryptoSymbols.map { $0.productId }
            setupCoinbaseBindings()
            Task {
                await coinbaseService.connect(productIds: productIds)
            }
        } else {
            coinbaseTasks.forEach { $0.cancel() }
            coinbaseTasks.removeAll()
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
        AppLogger.log("Stored price for \(update.productId): $\(update.price) (\(String(format: "%.2f", percentChange))%)", category: "PriceManager")
    }

    private func handleYahooUpdate(_ update: (symbol: String, price: Double, prevClose: Double)) {
        let percentChange = ((update.price - update.prevClose) / update.prevClose) * 100
        let priceData = PriceData(
            price: update.price,
            percentChange24h: percentChange,
            lastUpdated: Date()
        )
        prices[update.symbol] = priceData
        AppLogger.log("Stored price for \(update.symbol): $\(update.price) (\(String(format: "%.2f", percentChange))%)", category: "PriceManager")
    }
}
