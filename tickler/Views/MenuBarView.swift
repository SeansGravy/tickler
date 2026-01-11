import SwiftUI
import Combine

struct MenuBarView: View {
    @ObservedObject var appState: AppState
    @State private var refreshTrigger = false

    // Timer to force refresh every second
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Text(menuBarText)
            .font(.system(.body, design: .monospaced))
            .onReceive(timer) { _ in
                refreshTrigger.toggle()
            }
            .id(refreshTrigger)
    }

    private var menuBarText: String {
        if !appState.hasSymbols {
            return "+"
        }

        let parts = appState.displaySymbols.map { symbol -> String in
            symbolString(for: symbol)
        }

        return parts.joined(separator: " | ")
    }

    private func symbolString(for symbol: Symbol) -> String {
        guard let priceData = appState.price(for: symbol) else {
            return "\(symbol.ticker) ..."
        }

        if priceData.isStale {
            return "\(symbol.ticker) \u{26A0}"
        }

        let settings = appState.settings
        let priceStr = PriceFormatter.format(
            priceData.price,
            currency: settings.displayCurrency,
            compact: settings.compactPrices,
            decimals: settings.decimalPlaces
        )

        if settings.showPercentChange {
            let arrow = priceData.percentChange24h >= 0 ? "\u{25B2}" : "\u{25BC}"
            let pctStr = String(format: "%.1f", abs(priceData.percentChange24h))
            return "\(symbol.ticker) \(priceStr) \(arrow)\(pctStr)%"
        } else {
            return "\(symbol.ticker) \(priceStr)"
        }
    }
}
