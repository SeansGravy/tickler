import Foundation
import Combine

enum SymbolStoreError: LocalizedError {
    case symbolLimitReached
    case duplicateSymbol(String)

    var errorDescription: String? {
        switch self {
        case .symbolLimitReached:
            return "Maximum of 277 symbols reached"
        case .duplicateSymbol(let ticker):
            return "Symbol '\(ticker)' already exists"
        }
    }
}

@MainActor
final class SymbolStore: ObservableObject {
    @Published private(set) var symbols: [Symbol] = []
    @Published var searchText: String = ""

    private let fileURL: URL
    private let maxSymbols = 277  // Fibonacci number

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("tickler", isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)

        self.fileURL = appFolder.appendingPathComponent("symbols.json")
        load()
    }

    var cryptoSymbols: [Symbol] {
        symbols.filter { $0.type == .crypto }.sorted { $0.sortOrder < $1.sortOrder }
    }

    var stockSymbols: [Symbol] {
        symbols.filter { $0.type == .stock }.sorted { $0.sortOrder < $1.sortOrder }
    }

    var filteredSymbols: [Symbol] {
        let sorted = symbols.sorted { $0.sortOrder < $1.sortOrder }
        if searchText.isEmpty {
            return sorted
        }
        let search = searchText.lowercased()
        return sorted.filter {
            $0.ticker.lowercased().contains(search) ||
            $0.displayName.lowercased().contains(search)
        }
    }

    var canAddMore: Bool {
        symbols.count < maxSymbols
    }

    var symbolCount: Int {
        symbols.count
    }

    func topSymbols(count: Int) -> [Symbol] {
        Array(symbols.sorted { $0.sortOrder < $1.sortOrder }.prefix(count))
    }

    func symbol(withId id: UUID) -> Symbol? {
        symbols.first { $0.id == id }
    }

    func add(_ symbol: Symbol) throws {
        guard symbols.count < maxSymbols else {
            throw SymbolStoreError.symbolLimitReached
        }

        let normalizedTicker = symbol.ticker.uppercased()
        guard !symbols.contains(where: { $0.ticker == normalizedTicker && $0.type == symbol.type }) else {
            throw SymbolStoreError.duplicateSymbol(normalizedTicker)
        }

        var newSymbol = symbol
        newSymbol.sortOrder = symbols.count
        symbols.append(newSymbol)
        save()
    }

    func update(_ symbol: Symbol) {
        if let index = symbols.firstIndex(where: { $0.id == symbol.id }) {
            symbols[index] = symbol
            save()
        }
    }

    func remove(at offsets: IndexSet) {
        let sortedSymbols = symbols.sorted { $0.sortOrder < $1.sortOrder }
        let idsToRemove = offsets.map { sortedSymbols[$0].id }
        symbols.removeAll { idsToRemove.contains($0.id) }
        reindex()
        save()
    }

    func remove(symbol: Symbol) {
        symbols.removeAll { $0.id == symbol.id }
        reindex()
        save()
    }

    func move(from source: IndexSet, to destination: Int) {
        var sortedSymbols = symbols.sorted { $0.sortOrder < $1.sortOrder }
        sortedSymbols.move(fromOffsets: source, toOffset: destination)

        // Update sort orders
        for (index, var symbol) in sortedSymbols.enumerated() {
            symbol.sortOrder = index
            if let existingIndex = symbols.firstIndex(where: { $0.id == symbol.id }) {
                symbols[existingIndex].sortOrder = index
            }
        }
        save()
    }

    private func reindex() {
        let sorted = symbols.sorted { $0.sortOrder < $1.sortOrder }
        for (index, symbol) in sorted.enumerated() {
            if let existingIndex = symbols.firstIndex(where: { $0.id == symbol.id }) {
                symbols[existingIndex].sortOrder = index
            }
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            loadDefaults()
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            symbols = try JSONDecoder().decode([Symbol].self, from: data)
        } catch {
            print("Failed to load symbols: \(error)")
            loadDefaults()
        }
    }

    private func loadDefaults() {
        symbols = Self.defaultSymbols
        save()
    }

    private static var defaultSymbols: [Symbol] {
        [
            Symbol(ticker: "XRP", displayName: "Ripple", type: .crypto, exchange: .coinbase, sortOrder: 0),
            Symbol(ticker: "ETH", displayName: "Ethereum", type: .crypto, exchange: .coinbase, sortOrder: 1),
            Symbol(ticker: "BTC", displayName: "Bitcoin", type: .crypto, exchange: .coinbase, sortOrder: 2),
            Symbol(ticker: "SOL", displayName: "Solana", type: .crypto, exchange: .coinbase, sortOrder: 3),
            Symbol(ticker: "TSLA", displayName: "Tesla", type: .stock, exchange: .yahoo, sortOrder: 4),
            Symbol(ticker: "NVDA", displayName: "NVIDIA", type: .stock, exchange: .yahoo, sortOrder: 5),
            Symbol(ticker: "AAPL", displayName: "Apple", type: .stock, exchange: .yahoo, sortOrder: 6),
        ]
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(symbols)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save symbols: \(error)")
        }
    }
}
