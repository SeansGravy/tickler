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
        .frame(width: 280)
        .padding(.vertical, 8)
    }

    private var symbolList: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !appState.cryptoSymbols.isEmpty {
                SectionHeaderView(title: "CRYPTO")

                ForEach(appState.cryptoSymbols) { symbol in
                    SymbolRowView(symbol: symbol, price: appState.price(for: symbol))
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

                if !appState.settings.hasAlpacaCredentials {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Configure API key in Settings")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                } else {
                    ForEach(appState.stockSymbols) { symbol in
                        SymbolRowView(symbol: symbol, price: appState.price(for: symbol))
                            .onTapGesture {
                                appState.openSymbolURL(symbol)
                            }
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
            .keyboardShortcut(",", modifiers: .command)

            MenuButton(icon: "pencil", title: "Edit Symbols...") {
                appState.showingSymbolList = true
            }

            Divider()
                .padding(.vertical, 4)

            MenuButton(icon: "xmark.circle", title: "Quit tickler") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
    }

    private func openSettingsWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if #available(macOS 14, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
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

    var body: some View {
        HStack {
            Text(symbol.ticker)
                .fontWeight(.medium)
                .frame(width: 50, alignment: .leading)

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
                    .frame(width: 60, alignment: .trailing)
            } else {
                Text("--")
                    .foregroundColor(.secondary)
                    .frame(width: 100, alignment: .trailing)
                Text("--")
                    .foregroundColor(.secondary)
                    .frame(width: 60, alignment: .trailing)
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
                appState.showingAddSymbol = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}
