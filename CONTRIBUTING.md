# Contributing to tickler

Thank you for your interest in contributing to tickler!

## Development Setup

### Prerequisites

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (installed via Homebrew)

### Getting Started

1. Fork and clone the repository:
   ```bash
   git clone https://github.com/YOUR_USERNAME/tickler.git
   cd tickler
   ```

2. Generate the Xcode project:
   ```bash
   ./setup.sh
   ```

3. Open in Xcode:
   ```bash
   open tickler.xcodeproj
   ```

4. Build and run (`Cmd+R`)

### Project Structure

```
tickler/
├── tickler/
│   ├── ticklerApp.swift       # App entry point
│   ├── Models/                 # Data models
│   ├── ViewModels/             # ObservableObject view models
│   ├── Services/               # API clients, persistence
│   ├── Views/                  # SwiftUI views
│   ├── Utilities/              # Helpers and utilities
│   └── Resources/              # Assets, Info.plist
├── scripts/
│   └── build-dmg.sh           # DMG build script
├── project.yml                 # XcodeGen configuration
└── setup.sh                    # Project setup script
```

### Key Files

| File | Purpose |
|------|---------|
| `CoinbaseWebSocket.swift` | Real-time WebSocket client for crypto |
| `AlpacaAPI.swift` | REST client for stock prices |
| `AppState.swift` | Central app coordinator |
| `SymbolStore.swift` | Symbol persistence (JSON) |
| `SettingsManager.swift` | Settings persistence (UserDefaults) |

## Building

### Debug Build

```bash
xcodebuild -scheme tickler -configuration Debug build
```

### Release Build

```bash
xcodebuild -scheme tickler -configuration Release build
```

### Create DMG

```bash
./scripts/build-dmg.sh
```

## Code Style

- Follow Swift API Design Guidelines
- Use SwiftUI and Combine where appropriate
- Mark ViewModels with `@MainActor`
- Use actors for thread-safe networking code
- Keep views simple; move logic to ViewModels

## Pull Requests

1. Create a feature branch from `main`
2. Make your changes
3. Ensure the project builds without warnings
4. Submit a pull request with a clear description

## Reporting Issues

Please include:
- macOS version
- Steps to reproduce
- Expected vs actual behavior
- Console logs if applicable

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
