import SwiftUI

struct SymbolListView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAddSymbol = false
    @State private var symbolToDelete: Symbol?

    var body: some View {
        VStack(spacing: 0) {
            headerView

            if appState.symbols.isEmpty {
                emptyStateView
            } else {
                symbolList
            }

            footerView
        }
        .frame(width: 400, height: 500)
        .sheet(isPresented: $showingAddSymbol) {
            AddSymbolView()
                .environmentObject(appState)
        }
        .alert("Delete Symbol?", isPresented: .init(
            get: { symbolToDelete != nil },
            set: { if !$0 { symbolToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                symbolToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let symbol = symbolToDelete {
                    appState.removeSymbol(symbol)
                }
                symbolToDelete = nil
            }
        } message: {
            if let symbol = symbolToDelete {
                Text("Are you sure you want to remove \(symbol.ticker)?")
            }
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Manage Symbols")
                .font(.headline)
            Text("Drag to reorder. Top symbols appear in menu bar.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var symbolList: some View {
        List {
            ForEach(appState.symbols) { symbol in
                SymbolListRow(symbol: symbol) {
                    confirmDelete(symbol)
                }
            }
            .onMove { source, destination in
                appState.moveSymbols(from: source, to: destination)
            }
        }
        .listStyle(.plain)
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.bullet")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No symbols yet")
                .font(.headline)
            Text("Add symbols to start tracking prices")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footerView: some View {
        HStack {
            Button(action: { showingAddSymbol = true }) {
                Label("Add Symbol", systemImage: "plus")
            }
            .disabled(!appState.symbolStore.canAddMore)

            Spacer()

            Text("\(appState.symbolStore.symbolCount) of 256 symbols")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func confirmDelete(_ symbol: Symbol) {
        let isDisplayed = appState.displaySymbols.contains { $0.id == symbol.id }
        if isDisplayed {
            symbolToDelete = symbol
        } else {
            appState.removeSymbol(symbol)
        }
    }
}

struct SymbolListRow: View {
    let symbol: Symbol
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "line.3.horizontal")
                .foregroundColor(.secondary)

            Text(symbol.ticker)
                .fontWeight(.medium)
                .frame(width: 60, alignment: .leading)

            Text(symbol.displayName)
                .foregroundColor(.secondary)
                .lineLimit(1)

            Spacer()

            Text(symbol.exchange.displayName)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(4)

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
