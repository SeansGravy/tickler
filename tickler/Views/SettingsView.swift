import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    @State private var menuBarDisplayCount: Int = 1
    @State private var showPercentChange: Bool = true
    @State private var compactPrices: Bool = true
    @State private var decimalPlaces: Int = 2

    @State private var defaultCryptoExchange: Exchange = .coinbase
    @State private var defaultStockBroker: Exchange = .yahoo

    @State private var streamingEnabled: Bool = true
    @State private var stockRefreshInterval: StockRefreshInterval = .sixtySeconds
    @State private var pauseOnBattery: Bool = false

    @State private var alertsEnabled: Bool = false
    @State private var notificationStyle: NotificationStyle = .banner
    @State private var alertCooldown: AlertCooldown = .oneHour

    @State private var launchAtLogin: Bool = true

    @State private var showingResetConfirmation = false

    var body: some View {
        TabView {
            displayTab
                .tabItem {
                    Label("Display", systemImage: "display")
                }

            dataTab
                .tabItem {
                    Label("Data", systemImage: "arrow.triangle.2.circlepath")
                }

            alertsTab
                .tabItem {
                    Label("Alerts", systemImage: "bell")
                }

            systemTab
                .tabItem {
                    Label("System", systemImage: "gearshape")
                }
        }
        .frame(width: 450, height: 320)
        .onAppear {
            loadSettings()
        }
    }

    private var displayTab: some View {
        Form {
            Section("Menu Bar") {
                Picker("Symbols to display:", selection: $menuBarDisplayCount) {
                    ForEach(1...10, id: \.self) { count in
                        Text("\(count)").tag(count)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: menuBarDisplayCount) { _ in saveSettings() }

                Toggle("Show percent change", isOn: $showPercentChange)
                    .onChange(of: showPercentChange) { _ in saveSettings() }

                Toggle("Compact prices ($90.5k vs $90,468.60)", isOn: $compactPrices)
                    .onChange(of: compactPrices) { _ in saveSettings() }

                if !compactPrices {
                    Picker("Decimal places:", selection: $decimalPlaces) {
                        Text("0").tag(0)
                        Text("1").tag(1)
                        Text("2").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: decimalPlaces) { _ in saveSettings() }
                }
            }

            Section("Default Platforms") {
                Picker("Crypto exchange:", selection: $defaultCryptoExchange) {
                    ForEach(Exchange.cryptoExchanges, id: \.self) { exchange in
                        Text(exchange.displayName).tag(exchange)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: defaultCryptoExchange) { _ in saveSettings() }

                Picker("Stock broker:", selection: $defaultStockBroker) {
                    ForEach(Exchange.stockBrokers, id: \.self) { broker in
                        Text(broker.displayName).tag(broker)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: defaultStockBroker) { _ in saveSettings() }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var dataTab: some View {
        Form {
            Section("Crypto") {
                Toggle("Real-time streaming", isOn: $streamingEnabled)
                    .onChange(of: streamingEnabled) { _ in saveSettings() }

                Text("Uses Coinbase WebSocket for live price updates")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Stocks") {
                Picker("Refresh interval:", selection: $stockRefreshInterval) {
                    ForEach(StockRefreshInterval.allCases, id: \.self) { interval in
                        Text(interval.displayName).tag(interval)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: stockRefreshInterval) { _ in saveSettings() }

                Text("Uses Yahoo Finance (no API key required)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Power") {
                Toggle("Pause streaming on battery", isOn: $pauseOnBattery)
                    .onChange(of: pauseOnBattery) { _ in saveSettings() }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var alertsTab: some View {
        Form {
            Section("Notifications") {
                Toggle("Enable price alerts", isOn: $alertsEnabled)
                    .onChange(of: alertsEnabled) { _ in saveSettings() }

                if alertsEnabled {
                    Picker("Notification style:", selection: $notificationStyle) {
                        ForEach(NotificationStyle.allCases, id: \.self) { style in
                            Text(style.displayName).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: notificationStyle) { _ in saveSettings() }

                    Picker("Alert cooldown:", selection: $alertCooldown) {
                        ForEach(AlertCooldown.allCases, id: \.self) { cooldown in
                            Text(cooldown.displayName).tag(cooldown)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: alertCooldown) { _ in saveSettings() }
                }
            }

            if alertsEnabled {
                Section {
                    Text("Configure alerts per symbol in Edit Symbols")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var systemTab: some View {
        Form {
            Section("Startup") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _ in saveSettings() }
            }

            Section("Reset") {
                Button("Reset to Defaults") {
                    showingResetConfirmation = true
                }
                .foregroundColor(.red)
            }
        }
        .formStyle(.grouped)
        .padding()
        .alert("Reset Settings?", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                appState.resetSettings()
                loadSettings()
            }
        } message: {
            Text("This will reset all settings to their default values.")
        }
    }

    private func loadSettings() {
        let settings = appState.settings
        menuBarDisplayCount = settings.menuBarDisplayCount
        showPercentChange = settings.showPercentChange
        compactPrices = settings.compactPrices
        decimalPlaces = settings.decimalPlaces
        defaultCryptoExchange = settings.defaultCryptoExchange
        defaultStockBroker = settings.defaultStockBroker
        streamingEnabled = settings.streamingEnabled
        stockRefreshInterval = settings.stockRefreshInterval
        pauseOnBattery = settings.pauseOnBattery
        alertsEnabled = settings.alertsEnabled
        notificationStyle = settings.notificationStyle
        alertCooldown = settings.alertCooldown
        launchAtLogin = settings.launchAtLogin
    }

    private func saveSettings() {
        let newSettings = AppSettings(
            menuBarDisplayCount: menuBarDisplayCount,
            showPercentChange: showPercentChange,
            compactPrices: compactPrices,
            decimalPlaces: decimalPlaces,
            defaultCryptoExchange: defaultCryptoExchange,
            defaultStockBroker: defaultStockBroker,
            streamingEnabled: streamingEnabled,
            stockRefreshInterval: stockRefreshInterval,
            pauseOnBattery: pauseOnBattery,
            alertsEnabled: alertsEnabled,
            notificationStyle: notificationStyle,
            alertCooldown: alertCooldown,
            launchAtLogin: launchAtLogin
        )
        appState.updateSettings(newSettings)
    }
}
