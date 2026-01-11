import Foundation
import Combine

enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case reconnecting(attempt: Int)
    case failed(String)

    static func == (lhs: ConnectionState, rhs: ConnectionState) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected),
             (.connecting, .connecting),
             (.connected, .connected):
            return true
        case (.reconnecting(let a), .reconnecting(let b)):
            return a == b
        case (.failed(let a), .failed(let b)):
            return a == b
        default:
            return false
        }
    }
}

actor CoinbaseWebSocketService {
    private let url = URL(string: "wss://ws-feed.exchange.coinbase.com")!
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession
    private var reconnectAttempts = 0
    private let maxReconnectDelay: TimeInterval = 60
    private let baseDelay: TimeInterval = 1

    private var subscribedProducts: Set<String> = []
    private var isConnecting = false
    private var shouldReconnect = true

    private let priceSubject = PassthroughSubject<(productId: String, price: Double, open24h: Double), Never>()
    private let stateSubject = CurrentValueSubject<ConnectionState, Never>(.disconnected)

    var pricePublisher: AnyPublisher<(productId: String, price: Double, open24h: Double), Never> {
        priceSubject.eraseToAnyPublisher()
    }

    var statePublisher: AnyPublisher<ConnectionState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    init() {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }

    func connect(productIds: [String]) async {
        guard !productIds.isEmpty else {
            AppLogger.log("No product IDs to connect", category: "Coinbase")
            return
        }

        AppLogger.log("Connecting with products: \(productIds)", category: "Coinbase")
        subscribedProducts = Set(productIds)
        shouldReconnect = true
        await performConnect()
    }

    func disconnect() async {
        shouldReconnect = false
        subscribedProducts.removeAll()
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        stateSubject.send(.disconnected)
    }

    func updateSubscriptions(productIds: [String]) async {
        let newProducts = Set(productIds)
        let toUnsubscribe = subscribedProducts.subtracting(newProducts)
        let toSubscribe = newProducts.subtracting(subscribedProducts)

        if !toUnsubscribe.isEmpty {
            await sendUnsubscribe(productIds: Array(toUnsubscribe))
        }

        if !toSubscribe.isEmpty {
            await sendSubscribe(productIds: Array(toSubscribe))
        }

        subscribedProducts = newProducts
    }

    private func performConnect() async {
        guard !isConnecting else {
            AppLogger.log("Already connecting, skipping", category: "Coinbase")
            return
        }
        isConnecting = true

        AppLogger.log("Performing connect to \(url)", category: "Coinbase")
        stateSubject.send(.connecting)

        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()

        // Send subscription
        AppLogger.log("Sending subscription for \(subscribedProducts)", category: "Coinbase")
        await sendSubscribe(productIds: Array(subscribedProducts))

        isConnecting = false
        reconnectAttempts = 0
        stateSubject.send(.connected)
        AppLogger.log("Connected and subscribed", category: "Coinbase")

        // Start receiving messages
        await receiveMessages()
    }

    private func sendSubscribe(productIds: [String]) async {
        guard !productIds.isEmpty else { return }

        let subscription = CoinbaseSubscription(productIds: productIds)
        guard let data = try? JSONEncoder().encode(subscription),
              let jsonString = String(data: data, encoding: .utf8) else {
            AppLogger.log("Failed to encode subscription", category: "Coinbase")
            return
        }

        AppLogger.log("Sending subscription JSON: \(jsonString)", category: "Coinbase")

        do {
            try await webSocketTask?.send(.string(jsonString))
            AppLogger.log("Subscription sent successfully", category: "Coinbase")
        } catch {
            AppLogger.log("Failed to send subscription: \(error)", category: "Coinbase")
        }
    }

    private func sendUnsubscribe(productIds: [String]) async {
        guard !productIds.isEmpty else { return }

        let unsubscription = CoinbaseUnsubscription(productIds: productIds)
        guard let data = try? JSONEncoder().encode(unsubscription),
              let jsonString = String(data: data, encoding: .utf8) else { return }

        do {
            try await webSocketTask?.send(.string(jsonString))
        } catch {
            AppLogger.log("Failed to send unsubscription: \(error)", category: "Coinbase")
        }
    }

    private func receiveMessages() async {
        guard let webSocket = webSocketTask else { return }

        do {
            while true {
                let message = try await webSocket.receive()

                switch message {
                case .string(let text):
                    handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        handleMessage(text)
                    }
                @unknown default:
                    break
                }
            }
        } catch {
            await handleDisconnection(error: error)
        }
    }

    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let message = try? JSONDecoder().decode(CoinbaseMessage.self, from: data) else {
            AppLogger.log("Failed to decode message: \(text.prefix(100))", category: "Coinbase")
            return
        }

        // Only log ticker messages, skip subscriptions/heartbeat
        if message.type == "ticker" {
            guard let productId = message.productId,
                  let priceString = message.price,
                  let price = Double(priceString),
                  let open24hString = message.open24h,
                  let open24h = Double(open24hString) else {
                AppLogger.log("Ticker message missing fields: \(message.type)", category: "Coinbase")
                return
            }

            AppLogger.log("Price update: \(productId) = $\(price)", category: "Coinbase")
            priceSubject.send((productId: productId, price: price, open24h: open24h))
        } else {
            AppLogger.log("Received message type: \(message.type)", category: "Coinbase")
        }
    }

    private func handleDisconnection(error: Error) async {
        webSocketTask = nil

        guard shouldReconnect else {
            stateSubject.send(.disconnected)
            return
        }

        reconnectAttempts += 1
        stateSubject.send(.reconnecting(attempt: reconnectAttempts))

        let delay = calculateReconnectDelay(attempt: reconnectAttempts)

        do {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            await performConnect()
        } catch {
            stateSubject.send(.failed(error.localizedDescription))
        }
    }

    private func calculateReconnectDelay(attempt: Int) -> TimeInterval {
        let delay = baseDelay * pow(2.0, Double(attempt - 1))
        return min(delay, maxReconnectDelay)
    }
}

// MARK: - Coinbase Models

struct CoinbaseSubscription: Encodable {
    let type = "subscribe"
    let productIds: [String]
    let channels: [TickerChannel]

    struct TickerChannel: Encodable {
        let name = "ticker"
        let productIds: [String]

        enum CodingKeys: String, CodingKey {
            case name
            case productIds = "product_ids"
        }
    }

    enum CodingKeys: String, CodingKey {
        case type
        case productIds = "product_ids"
        case channels
    }

    init(productIds: [String]) {
        self.productIds = productIds
        self.channels = [TickerChannel(productIds: productIds)]
    }
}

struct CoinbaseUnsubscription: Encodable {
    let type = "unsubscribe"
    let productIds: [String]
    let channels: [TickerChannel]

    struct TickerChannel: Encodable {
        let name = "ticker"
        let productIds: [String]

        enum CodingKeys: String, CodingKey {
            case name
            case productIds = "product_ids"
        }
    }

    enum CodingKeys: String, CodingKey {
        case type
        case productIds = "product_ids"
        case channels
    }

    init(productIds: [String]) {
        self.productIds = productIds
        self.channels = [TickerChannel(productIds: productIds)]
    }
}

struct CoinbaseMessage: Decodable {
    let type: String
    let productId: String?
    let price: String?
    let open24h: String?
    let volume24h: String?
    let low24h: String?
    let high24h: String?

    enum CodingKeys: String, CodingKey {
        case type
        case productId = "product_id"
        case price
        case open24h = "open_24h"
        case volume24h = "volume_24h"
        case low24h = "low_24h"
        case high24h = "high_24h"
    }
}
