import SwiftUI

struct EditSymbolView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let symbol: Symbol

    @State private var displayName: String = ""
    @State private var exchange: Exchange = .coinbase

    @State private var alertEnabled: Bool = false
    @State private var alertAbovePrice: String = ""
    @State private var alertBelowPrice: String = ""
    @State private var alertPercentChange: String = ""

    var body: some View {
        VStack(spacing: 0) {
            headerView

            Form {
                Section("Symbol Details") {
                    HStack {
                        Text("Ticker")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(symbol.ticker)
                            .fontWeight(.medium)
                    }

                    HStack {
                        Text("Type")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(symbol.type == .crypto ? "Cryptocurrency" : "Stock")
                    }

                    TextField("Display Name", text: $displayName)

                    Picker("Exchange/Broker", selection: $exchange) {
                        if symbol.type == .crypto {
                            ForEach(Exchange.cryptoExchanges, id: \.self) { ex in
                                Text(ex.displayName).tag(ex)
                            }
                        } else {
                            ForEach(Exchange.stockBrokers, id: \.self) { broker in
                                Text(broker.displayName).tag(broker)
                            }
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Price Alerts") {
                    Toggle("Enable alerts for this symbol", isOn: $alertEnabled)

                    if alertEnabled {
                        HStack {
                            Text("Alert above $")
                            TextField("Price", text: $alertAbovePrice)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                        }

                        HStack {
                            Text("Alert below $")
                            TextField("Price", text: $alertBelowPrice)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                        }

                        HStack {
                            Text("Alert on % change")
                            TextField("Percent", text: $alertPercentChange)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 60)
                            Text("%")
                        }

                        Text("You'll be notified when the price crosses these thresholds")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .formStyle(.grouped)

            footerView
        }
        .frame(width: 400, height: 450)
        .onAppear {
            loadSymbolData()
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Edit \(symbol.ticker)")
                .font(.headline)
            Text("Modify symbol settings and alerts")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var footerView: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)

            Spacer()

            Button("Save") {
                saveChanges()
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func loadSymbolData() {
        displayName = symbol.displayName
        exchange = symbol.exchange
        alertEnabled = symbol.alertEnabled
        alertAbovePrice = symbol.alertAbovePrice.map { String($0) } ?? ""
        alertBelowPrice = symbol.alertBelowPrice.map { String($0) } ?? ""
        alertPercentChange = symbol.alertPercentChange.map { String($0) } ?? ""
    }

    private func saveChanges() {
        var updatedSymbol = symbol
        updatedSymbol.displayName = displayName.isEmpty ? symbol.ticker : displayName
        updatedSymbol.exchange = exchange
        updatedSymbol.alertEnabled = alertEnabled
        updatedSymbol.alertAbovePrice = Double(alertAbovePrice)
        updatedSymbol.alertBelowPrice = Double(alertBelowPrice)
        updatedSymbol.alertPercentChange = Double(alertPercentChange)

        appState.updateSymbol(updatedSymbol)
    }
}
