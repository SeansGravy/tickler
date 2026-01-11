import SwiftUI

struct DropdownView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !appState.hasSymbols {
                EmptyStateView()
            } else {
                symbolList
            }

            Divider()
                .padding(.vertical, 4)

            menuButtons
        }
        .frame(width: 300)
        .padding(.vertical, 8)
    }

    private var symbolList: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !appState.cryptoSymbols.isEmpty {
                SectionHeaderView(title: "CRYPTO")

                ForEach(appState.cryptoSymbols) { symbol in
                    SymbolRowView(
                        symbol: symbol,
                        price: appState.price(for: symbol),
                        settings: appState.settings
                    )
                    .onTapGesture {
                        appState.openSymbolURL(symbol)
                    }
                }
            }

            if !appState.stockSymbols.isEmpty {
                if !appState.cryptoSymbols.isEmpty {
                    Divider()
                        .padding(.vertical, 4)
                }

                SectionHeaderView(title: "STOCKS")

                ForEach(appState.stockSymbols) { symbol in
                    SymbolRowView(
                        symbol: symbol,
                        price: appState.price(for: symbol),
                        settings: appState.settings
                    )
                    .onTapGesture {
                        appState.openSymbolURL(symbol)
                    }
                }
            }
        }
    }

    private var menuButtons: some View {
        VStack(alignment: .leading, spacing: 2) {
            MenuButton(icon: "gearshape", title: "Settings...") {
                openSettingsWindow()
            }

            MenuButton(icon: "pencil", title: "Edit Symbols...") {
                openSymbolsWindow()
            }

            Divider()
                .padding(.vertical, 4)

            MenuButton(icon: "xmark.circle", title: "Quit Tickler") {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    private func openSettingsWindow() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "settings")
        }
    }

    private func openSymbolsWindow() {
        // Delay to let the popover close first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "symbols")
        }
    }
}

struct SectionHeaderView: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
    }
}

struct SymbolRowView: View {
    let symbol: Symbol
    let price: PriceData?
    let settings: AppSettings

    var body: some View {
        HStack {
            Text(symbol.ticker)
                .fontWeight(.medium)
                .frame(width: 50, alignment: .leading)

            if symbol.hasActiveAlerts {
                Image(systemName: "bell.fill")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }

            Spacer()

            if let price = price {
                if price.isStale {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
                Text(PriceFormatter.formatFull(price.price))
                    .frame(width: 100, alignment: .trailing)

                Text(PriceFormatter.formatPercentChange(price.percentChange24h))
                    .foregroundColor(price.percentChange24h >= 0 ? .green : .red)
                    .frame(width: 70, alignment: .trailing)
            } else {
                Text("--")
                    .foregroundColor(.secondary)
                    .frame(width: 100, alignment: .trailing)
                Text("--")
                    .foregroundColor(.secondary)
                    .frame(width: 70, alignment: .trailing)
            }
        }
        .font(.system(.body, design: .monospaced))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .background(Color.clear)
        .onHover { isHovered in
            if isHovered {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

struct MenuButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 16)
                Text(title)
                Spacer()
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

struct EmptyStateView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "plus.circle")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No symbols added")
                .font(.headline)
            Text("Add your first symbol to start tracking prices")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Add Symbol") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "symbols")
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}
