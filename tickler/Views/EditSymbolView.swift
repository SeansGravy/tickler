import SwiftUI

struct EditSymbolView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let symbol: Symbol

    @State private var ticker: String
    @State private var displayName: String
    @State private var type: SymbolType
    @State private var exchange: Exchange
    @State private var group: String
    @State private var tradingPlatformOverride: TradingPlatform?
    @State private var useDefaultPlatform: Bool

    // Alerts
    @State private var alertEnabled: Bool
    @State private var alertAbovePrice: String
    @State private var alertBelowPrice: String
    @State private var alertPercentChange: String

    init(symbol: Symbol) {
        self.symbol = symbol
        _ticker = State(initialValue: symbol.ticker)
        _displayName = State(initialValue: symbol.displayName)
        _type = State(initialValue: symbol.type)
        _exchange = State(initialValue: symbol.exchange)
        _group = State(initialValue: symbol.group ?? "")
        _tradingPlatformOverride = State(initialValue: symbol.tradingPlatformOverride)
        _useDefaultPlatform = State(initialValue: symbol.tradingPlatformOverride == nil)
        _alertEnabled = State(initialValue: symbol.alertEnabled)
        _alertAbovePrice = State(initialValue: symbol.alertAbovePrice.map { String($0) } ?? "")
        _alertBelowPrice = State(initialValue: symbol.alertBelowPrice.map { String($0) } ?? "")
        _alertPercentChange = State(initialValue: symbol.alertPercentChange.map { String($0) } ?? "")
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Edit Symbol")
                    .font(.headline)
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    saveSymbol()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(ticker.isEmpty || displayName.isEmpty)
            }
            .padding()

            Divider()

            Form {
                basicInfoSection
                tradingSection
                alertsSection
            }
            .formStyle(.grouped)
        }
        .frame(width: 400, height: 500)
    }

    private var basicInfoSection: some View {
        Section("Basic Info") {
            TextField("Ticker", text: $ticker)
                .textCase(.uppercase)
                .disabled(true) // Can't change ticker on edit

            TextField("Display Name", text: $displayName)

            Picker("Type", selection: $type) {
                Text("Crypto").tag(SymbolType.crypto)
                Text("Stock").tag(SymbolType.stock)
            }
            .disabled(true) // Can't change type on edit

            Picker("Exchange", selection: $exchange) {
                if type == .crypto {
                    ForEach(Exchange.cryptoExchanges, id: \.self) { ex in
                        Text(ex.displayName).tag(ex)
                    }
                } else {
                    ForEach(Exchange.stockBrokers, id: \.self) { ex in
                        Text(ex.displayName).tag(ex)
                    }
                }
            }

            TextField("Group (optional)", text: $group)
        }
    }

    private var tradingSection: some View {
        Section("Trading Platform") {
            Toggle("Use default platform", isOn: $useDefaultPlatform)

            if !useDefaultPlatform {
                Picker("Open in", selection: $tradingPlatformOverride) {
                    Text("None").tag(nil as TradingPlatform?)
                    ForEach(TradingPlatform.allCases, id: \.self) { platform in
                        Text(platform.displayName).tag(platform as TradingPlatform?)
                    }
                }
            }
        }
    }

    private var alertsSection: some View {
        Section("Alerts") {
            Toggle("Enable alerts for this symbol", isOn: $alertEnabled)

            if alertEnabled {
                HStack {
                    Text("Alert when price above:")
                    Spacer()
                    TextField("Price", text: $alertAbovePrice)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }

                HStack {
                    Text("Alert when price below:")
                    Spacer()
                    TextField("Price", text: $alertBelowPrice)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }

                HStack {
                    Text("Alert on % change ±:")
                    Spacer()
                    TextField("%", text: $alertPercentChange)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }

                Text("Leave fields empty to disable that alert type")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func saveSymbol() {
        var updatedSymbol = symbol
        updatedSymbol.displayName = displayName
        updatedSymbol.exchange = exchange
        updatedSymbol.group = group.isEmpty ? nil : group
        updatedSymbol.tradingPlatformOverride = useDefaultPlatform ? nil : tradingPlatformOverride
        updatedSymbol.alertEnabled = alertEnabled
        updatedSymbol.alertAbovePrice = Double(alertAbovePrice)
        updatedSymbol.alertBelowPrice = Double(alertBelowPrice)
        updatedSymbol.alertPercentChange = Double(alertPercentChange)

        appState.updateSymbol(updatedSymbol)
        dismiss()
    }
}
