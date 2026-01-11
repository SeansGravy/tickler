import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var settings: AppSettings = .default
    @State private var showingResetConfirmation = false

    var body: some View {
        Form {
            displaySection
            defaultsSection
            dataSection
            alertsSection
            systemSection
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 580)
        .onAppear {
            settings = appState.settings
        }
        .onChange(of: settings) { newValue in
            appState.updateSettings(newValue)
        }
        .alert("Reset to Defaults?", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                appState.resetSettings()
                settings = appState.settings
            }
        } message: {
            Text("This will reset all settings to their default values.")
        }
    }

    private var displaySection: some View {
        Section("Display") {
            Stepper(
                "Symbols in menu bar: \(settings.menuBarDisplayCount)",
                value: $settings.menuBarDisplayCount,
                in: 1...10
            )

            Toggle("Show percent change", isOn: $settings.showPercentChange)

            Toggle("Compact prices", isOn: $settings.compactPrices)

            Stepper(
                "Decimal places: \(settings.decimalPlaces)",
                value: $settings.decimalPlaces,
                in: 0...6
            )

            Picker("Display currency", selection: $settings.displayCurrency) {
                ForEach(Currency.allCases, id: \.self) { currency in
                    Text(currency.displayName).tag(currency)
                }
            }

            Picker("Color theme", selection: $settings.colorTheme) {
                ForEach(ColorTheme.allCases, id: \.self) { theme in
                    Text(theme.displayName).tag(theme)
                }
            }
        }
    }

    private var defaultsSection: some View {
        Section("Defaults") {
            Picker("Default crypto exchange", selection: $settings.defaultCryptoExchange) {
                ForEach(Exchange.cryptoExchanges, id: \.self) { exchange in
                    Text(exchange.displayName).tag(exchange)
                }
            }

            Picker("Default stock broker", selection: $settings.defaultStockBroker) {
                ForEach(Exchange.stockBrokers, id: \.self) { broker in
                    Text(broker.displayName).tag(broker)
                }
            }
        }
    }

    private var dataSection: some View {
        Section("Data") {
            Toggle("Real-time crypto streaming", isOn: $settings.streamingEnabled)

            Picker("Stock refresh interval", selection: $settings.stockRefreshInterval) {
                ForEach(StockRefreshInterval.allCases, id: \.self) { interval in
                    Text(interval.displayName).tag(interval)
                }
            }

            Toggle("Pause streaming on battery", isOn: $settings.pauseOnBattery)
        }
    }

    private var alertsSection: some View {
        Section("Alerts") {
            Toggle("Enable alerts", isOn: $settings.alertsEnabled)

            Picker("Notification style", selection: $settings.notificationStyle) {
                ForEach(NotificationStyle.allCases, id: \.self) { style in
                    Text(style.displayName).tag(style)
                }
            }
            .disabled(!settings.alertsEnabled)

            Picker("Alert cooldown", selection: $settings.alertCooldown) {
                ForEach(AlertCooldown.allCases, id: \.self) { cooldown in
                    Text(cooldown.displayName).tag(cooldown)
                }
            }
            .disabled(!settings.alertsEnabled)
        }
    }

    private var systemSection: some View {
        Section("System") {
            Toggle("Launch at login", isOn: $settings.launchAtLogin)
                .onChange(of: settings.launchAtLogin) { newValue in
                    try? LaunchAtLoginManager.setEnabled(newValue)
                }

            Button("Reset to Defaults") {
                showingResetConfirmation = true
            }
            .foregroundColor(.red)
        }
    }
}
