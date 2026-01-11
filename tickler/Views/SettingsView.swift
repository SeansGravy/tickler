import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    @State private var menuBarDisplayCount: Int = 1
    @State private var defaultCryptoExchange: Exchange = .coinbase
    @State private var defaultStockBroker: Exchange = .alpaca
    @State private var launchAtLogin: Bool = true
    @State private var streamingEnabled: Bool = true
    @State private var alpacaAPIKey: String = ""
    @State private var alpacaAPISecret: String = ""

    var body: some View {
        Form {
            displaySection
            defaultsSection
            dataSection
            alpacaSection
            systemSection
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 500)
        .onAppear {
            loadSettings()
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    loadSettings()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveSettings()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var displaySection: some View {
        Section("Display") {
            Picker("Symbols in menu bar:", selection: $menuBarDisplayCount) {
                ForEach(1...10, id: \.self) { count in
                    Text("\(count)").tag(count)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var defaultsSection: some View {
        Section("Defaults") {
            Picker("Crypto exchange:", selection: $defaultCryptoExchange) {
                ForEach(Exchange.cryptoExchanges, id: \.self) { exchange in
                    Text(exchange.displayName).tag(exchange)
                }
            }
            .pickerStyle(.segmented)

            Picker("Stock broker:", selection: $defaultStockBroker) {
                ForEach(Exchange.stockExchanges, id: \.self) { exchange in
                    Text(exchange.displayName).tag(exchange)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var dataSection: some View {
        Section("Data") {
            Toggle("Enable real-time streaming", isOn: $streamingEnabled)
            Text("Disable to reduce battery and bandwidth usage")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var alpacaSection: some View {
        Section("Alpaca API (Required for stocks)") {
            SecureField("API Key ID", text: $alpacaAPIKey)
                .textFieldStyle(.roundedBorder)

            SecureField("API Secret", text: $alpacaAPISecret)
                .textFieldStyle(.roundedBorder)

            Link("Get API keys from Alpaca",
                 destination: URL(string: "https://app.alpaca.markets/paper/dashboard/overview")!)
                .font(.caption)
        }
    }

    private var systemSection: some View {
        Section("System") {
            Toggle("Launch at login", isOn: $launchAtLogin)
        }
    }

    private func loadSettings() {
        let settings = appState.settings
        menuBarDisplayCount = settings.menuBarDisplayCount
        defaultCryptoExchange = settings.defaultCryptoExchange
        defaultStockBroker = settings.defaultStockBroker
        launchAtLogin = settings.launchAtLogin
        streamingEnabled = settings.streamingEnabled
        alpacaAPIKey = settings.alpacaAPIKey
        alpacaAPISecret = settings.alpacaAPISecret
    }

    private func saveSettings() {
        let newSettings = AppSettings(
            menuBarDisplayCount: menuBarDisplayCount,
            defaultCryptoExchange: defaultCryptoExchange,
            defaultStockBroker: defaultStockBroker,
            launchAtLogin: launchAtLogin,
            streamingEnabled: streamingEnabled,
            alpacaAPIKey: alpacaAPIKey,
            alpacaAPISecret: alpacaAPISecret
        )
        appState.updateSettings(newSettings)
    }
}
