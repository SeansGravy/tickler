import SwiftUI

struct MenuBarView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        HStack(spacing: 4) {
            if !appState.hasSymbols {
                Image(systemName: "plus.circle")
            } else if appState.isOffline {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Offline")
            } else {
                ForEach(Array(appState.displaySymbols.enumerated()), id: \.element.id) { index, symbol in
                    if index > 0 {
                        Text("|")
                            .foregroundColor(.secondary)
                    }
                    SymbolTickerView(symbol: symbol, price: appState.price(for: symbol))
                }
            }
        }
    }
}

struct SymbolTickerView: View {
    let symbol: Symbol
    let price: PriceData?

    var body: some View {
        HStack(spacing: 2) {
            Text(symbol.ticker)
                .fontWeight(.medium)

            if let price = price {
                if price.isStale {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                } else {
                    Text(PriceFormatter.formatCompact(price.price))
                    Text(PriceFormatter.formatPercentChange(price.percentChange24h))
                        .foregroundColor(price.percentChange24h >= 0 ? .green : .red)
                }
            } else {
                Text("--")
                    .foregroundColor(.secondary)
            }
        }
        .font(.system(.caption, design: .monospaced))
    }
}
