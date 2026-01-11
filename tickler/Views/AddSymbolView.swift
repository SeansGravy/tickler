import SwiftUI

struct AddSymbolView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var ticker = ""
    @State private var displayName = ""
    @State private var symbolType: SymbolType = .crypto
    @State private var exchange: Exchange = .coinbase
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Symbol")
                .font(.headline)

            Form {
                TextField("Ticker:", text: $ticker)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: ticker) { newValue in
                        ticker = newValue.uppercased()
                    }

                TextField("Name (optional):", text: $displayName)
                    .textFieldStyle(.roundedBorder)

                Picker("Type:", selection: $symbolType) {
                    Text("Crypto").tag(SymbolType.crypto)
                    Text("Stock").tag(SymbolType.stock)
                }
                .pickerStyle(.segmented)
                .onChange(of: symbolType) { newType in
                    updateExchangeForType(newType)
                }

                Picker("Exchange:", selection: $exchange) {
                    ForEach(exchangesForType, id: \.self) { ex in
                        Text(ex.displayName).tag(ex)
                    }
                }
                .pickerStyle(.menu)
            }
            .formStyle(.columns)

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Spacer()

                Button("Add") {
                    addSymbol()
                }
                .buttonStyle(.borderedProminent)
                .disabled(ticker.isEmpty)
                .keyboardShortcut(.return)
            }
        }
        .padding()
        .frame(width: 300)
        .onAppear {
            updateExchangeForType(symbolType)
        }
    }

    private var exchangesForType: [Exchange] {
        switch symbolType {
        case .crypto:
            return Exchange.cryptoExchanges
        case .stock:
            return Exchange.stockBrokers
        }
    }

    private func updateExchangeForType(_ type: SymbolType) {
        switch type {
        case .crypto:
            exchange = appState.settings.defaultCryptoExchange
        case .stock:
            exchange = appState.settings.defaultStockBroker
        }
    }

    private func addSymbol() {
        let name = displayName.isEmpty ? ticker : displayName

        let symbol = Symbol(
            ticker: ticker,
            displayName: name,
            type: symbolType,
            exchange: exchange
        )

        do {
            try appState.symbolStore.add(symbol)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
