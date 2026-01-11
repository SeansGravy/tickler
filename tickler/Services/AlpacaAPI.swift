import Foundation
import Combine

final class AlpacaAPIService {
    private let baseURL = URL(string: "https://data.alpaca.markets/v2")!
    private var apiKey: String = ""
    private var secretKey: String = ""
    private var session: URLSession
    private var pollTimer: Timer?
    private var symbols: [String] = []

    private let priceSubject = PassthroughSubject<(symbol: String, price: Double, prevClose: Double), Never>()
    private let errorSubject = PassthroughSubject<Error, Never>()

    var pricePublisher: AnyPublisher<(symbol: String, price: Double, prevClose: Double), Never> {
        priceSubject.eraseToAnyPublisher()
    }

    var errorPublisher: AnyPublisher<Error, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    var hasCredentials: Bool {
        !apiKey.isEmpty && !secretKey.isEmpty
    }

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    func updateCredentials(apiKey: String, secretKey: String) {
        self.apiKey = apiKey
        self.secretKey = secretKey
    }

    func startPolling(symbols: [String]) {
        self.symbols = symbols
        stopPolling()

        guard hasCredentials, !symbols.isEmpty else { return }

        // Fetch immediately
        Task {
            await fetchAllQuotes()
        }

        // Then poll every 60 seconds
        pollTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
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
            startPolling(symbols: symbols)
        }
    }

    private func fetchAllQuotes() async {
        guard hasCredentials else { return }

        for symbol in symbols {
            do {
                let (price, prevClose) = try await fetchSnapshot(symbol: symbol)
                priceSubject.send((symbol: symbol, price: price, prevClose: prevClose))
            } catch {
                errorSubject.send(error)
            }
        }
    }

    private func fetchSnapshot(symbol: String) async throws -> (price: Double, prevClose: Double) {
        let url = baseURL.appendingPathComponent("stocks/\(symbol)/snapshot")

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "APCA-API-KEY-ID")
        request.setValue(secretKey, forHTTPHeaderField: "APCA-API-SECRET-KEY")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AlpacaError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw AlpacaError.unauthorized
            }
            if httpResponse.statusCode == 429 {
                throw AlpacaError.rateLimited
            }
            throw AlpacaError.httpError(httpResponse.statusCode)
        }

        let snapshot = try JSONDecoder().decode(AlpacaSnapshotResponse.self, from: data)

        guard let trade = snapshot.latestTrade else {
            throw AlpacaError.noData
        }

        let price = trade.p
        let prevClose = snapshot.prevDailyBar?.c ?? price

        return (price: price, prevClose: prevClose)
    }
}

enum AlpacaError: LocalizedError {
    case invalidResponse
    case unauthorized
    case rateLimited
    case httpError(Int)
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Alpaca"
        case .unauthorized:
            return "Invalid API credentials"
        case .rateLimited:
            return "Rate limit exceeded"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .noData:
            return "No data available for symbol"
        }
    }
}
