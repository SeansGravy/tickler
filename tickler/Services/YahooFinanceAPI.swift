import Foundation
import Combine

struct YahooChartResponse: Decodable {
    let chart: Chart

    struct Chart: Decodable {
        let result: [Result]?
        let error: YahooError?
    }

    struct Result: Decodable {
        let meta: Meta
        let indicators: Indicators?
    }

    struct Meta: Decodable {
        let regularMarketPrice: Double?
        let previousClose: Double?
        let symbol: String
    }

    struct Indicators: Decodable {
        let quote: [Quote]?
    }

    struct Quote: Decodable {
        let close: [Double?]?
        let open: [Double?]?
    }

    struct YahooError: Decodable {
        let code: String
        let description: String
    }
}

final class YahooFinanceService {
    private let baseURL = "https://query1.finance.yahoo.com/v8/finance/chart"
    private var session: URLSession
    private var pollTimer: Timer?
    private var symbols: [String] = []
    private var refreshInterval: TimeInterval = 60

    private let priceSubject = PassthroughSubject<(symbol: String, price: Double, prevClose: Double), Never>()
    private let errorSubject = PassthroughSubject<Error, Never>()

    var pricePublisher: AnyPublisher<(symbol: String, price: Double, prevClose: Double), Never> {
        priceSubject.eraseToAnyPublisher()
    }

    var errorPublisher: AnyPublisher<Error, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    func startPolling(symbols: [String], interval: TimeInterval = 60) {
        self.symbols = symbols
        self.refreshInterval = interval
        stopPolling()

        guard !symbols.isEmpty else { return }

        // Fetch immediately
        Task {
            await fetchAllQuotes()
        }

        // Then poll at interval
        pollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task {
                await self?.fetchAllQuotes()
            }
        }
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    func updateSymbols(_ symbols: [String]) {
        self.symbols = symbols
        if pollTimer != nil {
            startPolling(symbols: symbols, interval: refreshInterval)
        }
    }

    func updateInterval(_ interval: TimeInterval) {
        self.refreshInterval = interval
        if pollTimer != nil && !symbols.isEmpty {
            startPolling(symbols: symbols, interval: interval)
        }
    }

    private func fetchAllQuotes() async {
        for symbol in symbols {
            do {
                let (price, prevClose) = try await fetchQuote(symbol: symbol)
                priceSubject.send((symbol: symbol, price: price, prevClose: prevClose))
            } catch {
                errorSubject.send(error)
            }
        }
    }

    private func fetchQuote(symbol: String) async throws -> (price: Double, prevClose: Double) {
        guard let url = URL(string: "\(baseURL)/\(symbol)?interval=1d&range=2d") else {
            throw YahooError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw YahooError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw YahooError.httpError(httpResponse.statusCode)
        }

        let chartResponse = try JSONDecoder().decode(YahooChartResponse.self, from: data)

        if let error = chartResponse.chart.error {
            throw YahooError.apiError(error.description)
        }

        guard let result = chartResponse.chart.result?.first else {
            throw YahooError.noData
        }

        let meta = result.meta
        guard let price = meta.regularMarketPrice else {
            throw YahooError.noPrice
        }

        let prevClose = meta.previousClose ?? price

        return (price: price, prevClose: prevClose)
    }
}

enum YahooError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case noData
    case noPrice

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from Yahoo Finance"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(let message):
            return "API error: \(message)"
        case .noData:
            return "No data available for symbol"
        case .noPrice:
            return "No price data available"
        }
    }
}
