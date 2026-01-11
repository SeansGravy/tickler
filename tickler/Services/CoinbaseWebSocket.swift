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
        guard !productIds.isEmpty else { return }

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
        guard !isConnecting else { return }
        isConnecting = true

        stateSubject.send(.connecting)

        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()

        // Send subscription
        await sendSubscribe(productIds: Array(subscribedProducts))

        isConnecting = false
        reconnectAttempts = 0
        stateSubject.send(.connected)

        // Start receiving messages
        await receiveMessages()
    }

    private func sendSubscribe(productIds: [String]) async {
        guard !productIds.isEmpty else { return }

        let subscription = CoinbaseSubscription(productIds: productIds)
        guard let data = try? JSONEncoder().encode(subscription),
              let jsonString = String(data: data, encoding: .utf8) else { return }

        do {
            try await webSocketTask?.send(.string(jsonString))
        } catch {
            print("Failed to send subscription: \(error)")
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
            print("Failed to send unsubscription: \(error)")
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
            return
        }

        guard message.type == "ticker",
              let productId = message.productId,
              let priceString = message.price,
              let price = Double(priceString),
              let open24hString = message.open24h,
              let open24h = Double(open24hString) else {
            return
        }

        priceSubject.send((productId: productId, price: price, open24h: open24h))
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
