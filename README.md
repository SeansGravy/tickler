# tickler

A native macOS menu bar app for tracking cryptocurrency and stock prices in real-time.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![License MIT](https://img.shields.io/badge/License-MIT-green)

## Download

**[Download tickler.dmg](https://github.com/SeansGravy/tickler/releases/latest/download/tickler.dmg)**

*First launch: Right-click and Open to bypass Gatekeeper (unsigned app)*

## Features

- **Real-time crypto prices** via Coinbase WebSocket
- **Stock prices** via Yahoo Finance (no API key required)
- **Multi-currency support** - USD, EUR, GBP, JPY, CAD, AUD, CHF, CNY
- **Price alerts** with customizable thresholds and notifications
- **Click-to-trade** opens your preferred broker/exchange
- **Menu bar display** showing up to 10 symbols with compact formatting
- **24h high/low** displayed in dropdown for each symbol
- **Drag-to-reorder** symbol management with search
- **Color themes** - Green/Red, Blue/Orange, Monochrome
- **Launch at login** support
- **Offline detection** with stale data indicators
- **Zero API keys required** - works out of the box

## Supported Platforms

| Type | Platform | Click-to-trade |
|------|----------|----------------|
| Crypto | Coinbase | coinbase.com |
| Crypto | Kraken | kraken.com |
| Stocks | Yahoo Finance | finance.yahoo.com |
| Stocks | Robinhood | robinhood.com |
| Stocks | TradingView | tradingview.com |

## Installation

### From DMG (Recommended)

1. Download the latest `tickler.dmg` from [Releases](https://github.com/SeansGravy/tickler/releases)
2. Open the DMG and drag `tickler.app` to Applications
3. **Important:** Since the app is unsigned, you'll need to bypass Gatekeeper:
   - Right-click (or Control-click) on `tickler.app`
   - Select **"Open"** from the context menu
   - Click **"Open"** in the security dialog
4. The app will appear in your menu bar

### From Source

```bash
# Clone the repository
git clone https://github.com/SeansGravy/tickler.git
cd tickler

# Generate Xcode project (requires xcodegen)
./setup.sh

# Open in Xcode
open tickler.xcodeproj
```

Build and run with `Cmd+R`. The app will appear in your menu bar.

## Usage

### Adding Symbols

1. Click the tickler icon in your menu bar
2. Click **Edit Symbols** or the **+** button
3. Enter the ticker symbol (e.g., `BTC`, `AAPL`)
4. Select crypto or stock type
5. Choose the exchange/broker

### Menu Bar Display

The menu bar shows your top symbols in compact format:

```
BTC $104.5k ▲2.3% | ETH $3.9k ▼0.5%
```

- Configure how many symbols to display in Settings (1-10)
- Drag symbols to reorder them in the Edit Symbols view
- Top symbols appear in the menu bar

### Click-to-Trade

Click any symbol in the dropdown to open its page on your chosen platform:
- Crypto: Opens Coinbase or Kraken price page
- Stocks: Opens Yahoo Finance, Robinhood, or TradingView

### Price Alerts

1. Open **Edit Symbols**
2. Click the pencil icon on any symbol
3. Enable alerts and set thresholds:
   - Alert when price goes above a value
   - Alert when price goes below a value
   - Alert on percent change threshold
4. Alerts appear as macOS notifications

Configure notification style and cooldown in Settings > Alerts.

### Per-Symbol Settings

When editing a symbol, you can also:
- Set a custom trading platform override (opens in a different broker than default)
- Add the symbol to a group for organization

### Price Formatting

| Price Range | Format |
|-------------|--------|
| >= $1,000,000 | $1.2M |
| >= $1,000 | $104.5k |
| < $1,000 | $123.45 |

### Indicators

- **up arrow** Green: positive 24h change
- **down arrow** Red: negative 24h change
- **warning sign**: stale data (>60s old) or connection issue
- **bell icon**: symbol has active price alerts

## Settings

### Display
- Number of symbols in menu bar (1-10)
- Show/hide percent change
- Compact prices ($90.5k) vs full prices ($90,468.60)
- Decimal places (0-6) for price display
- Display currency (USD, EUR, GBP, JPY, CAD, AUD, CHF, CNY)
- Color theme (Green/Red, Blue/Orange, Monochrome)

### Defaults
- Default crypto exchange (Coinbase, Kraken)
- Default stock broker (Yahoo Finance, Robinhood, TradingView)

### Data
- Real-time streaming toggle for crypto
- Stock refresh interval (15s, 30s, 1m, 5m)
- Pause streaming on battery

### Alerts
- Enable/disable price alerts globally
- Notification style (banner, sound, both)
- Alert cooldown period (5m to 4h)

### System
- Launch at login
- Reset to defaults

## Data Sources

| Type | Source | Update Frequency |
|------|--------|------------------|
| Crypto | Coinbase WebSocket | Real-time |
| Stocks | Yahoo Finance | Configurable (15s-5m) |

## Storage

- **Settings:** `~/Library/Preferences` (UserDefaults)
- **Symbols:** `~/Library/Application Support/tickler/symbols.json`

## Requirements

- macOS 13.0 (Ventura) or later
- Internet connection
- No API keys required

## Building a DMG

```bash
./scripts/build-dmg.sh
```

Output: `build/tickler.dmg`

## License

MIT License - see [LICENSE](LICENSE) for details.

## Support

If you find tickler useful, consider supporting development:

[Buy Me a Coffee](https://buymeacoffee.com/wedigp9ylf)

[GitHub Sponsors](https://github.com/sponsors/SeansGravy)

## Credits

Built with SwiftUI and love by [SeansGravy](https://github.com/SeansGravy).
