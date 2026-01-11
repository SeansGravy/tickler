# tickler

A native macOS menu bar app for tracking cryptocurrency and stock prices in real-time.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![License MIT](https://img.shields.io/badge/License-MIT-green)

## Download

**[⬇️ Download tickler.dmg](https://github.com/SeansGravy/tickler/releases/latest/download/tickler.dmg)**

*First launch: Right-click → Open to bypass Gatekeeper (unsigned app)*

## Features

- **Real-time crypto prices** via Coinbase WebSocket (no API key required)
- **Stock prices** via Alpaca Markets API (free account required)
- **Menu bar display** showing up to 10 symbols with compact formatting
- **Drag-to-reorder** symbol management
- **Launch at login** support
- **Offline detection** with stale data indicators
- Supports **Coinbase** and **Kraken** for crypto, **Alpaca** for stocks

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

## Alpaca Setup (for Stock Prices)

Stock prices require a free Alpaca Markets account:

1. Sign up at [alpaca.markets](https://alpaca.markets)
2. Go to your [Paper Trading Dashboard](https://app.alpaca.markets/paper/dashboard/overview)
3. Navigate to **API Keys** and generate a new key pair
4. In tickler, click the menu bar icon → **Settings**
5. Enter your API Key ID and Secret Key
6. Save settings

**Note:** Free Alpaca accounts provide 15-minute delayed data.

## Usage

### Adding Symbols

1. Click the tickler icon in your menu bar
2. Click **Edit Symbols** or the **+** button
3. Enter the ticker symbol (e.g., `BTC`, `AAPL`)
4. Select crypto or stock type
5. Choose the exchange (Coinbase/Kraken for crypto, Alpaca for stocks)

### Menu Bar Display

The menu bar shows your top symbols in compact format:

```
BTC $104.5k ▲2.3% | ETH $3.9k ▼0.5%
```

- Configure how many symbols to display in Settings (1-10)
- Drag symbols to reorder them in the Edit Symbols view
- Top symbols appear in the menu bar

### Price Formatting

| Price Range | Format |
|-------------|--------|
| ≥ $1,000,000 | $1.2M |
| ≥ $1,000 | $104.5k |
| < $1,000 | $123.45 |

### Indicators

- **▲** Green arrow: positive 24h change
- **▼** Red arrow: negative 24h change
- **⚠️** Warning: stale data (>60s old) or connection issue

## Data Sources

| Type | Source | Update Frequency |
|------|--------|------------------|
| Crypto | Coinbase WebSocket | Real-time |
| Crypto | Kraken | Real-time |
| Stocks | Alpaca REST API | 60 seconds |

## Storage

- **Settings:** `~/Library/Preferences` (UserDefaults)
- **Symbols:** `~/Library/Application Support/tickler/symbols.json`

## Requirements

- macOS 13.0 (Ventura) or later
- For stocks: Alpaca Markets account (free)

## Building a DMG

```bash
./scripts/build-dmg.sh
```

Output: `build/tickler.dmg`

## License

MIT License - see [LICENSE](LICENSE) for details.

## Support

If you find tickler useful, consider supporting development:

☕ [Buy Me a Coffee](https://buymeacoffee.com/wedigp9ylf)

💜 [GitHub Sponsors](https://github.com/sponsors/SeansGravy)

## Credits

Built with SwiftUI and love by [SeansGravy](https://github.com/SeansGravy).
