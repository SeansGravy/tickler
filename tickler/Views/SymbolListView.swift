import SwiftUI

struct SymbolListView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAddSymbol = false
    @State private var editingSymbol: Symbol?
    @State private var symbolToDelete: Symbol?
    @State private var draggingSymbol: Symbol?

    var body: some View {
        VStack(spacing: 0) {
            headerView

            searchField

            if appState.symbolStore.filteredSymbols.isEmpty {
                if appState.symbolStore.searchText.isEmpty {
                    emptyStateView
                } else {
                    noResultsView
                }
            } else {
                symbolList
            }

            footerView
        }
        .frame(minWidth: 450, minHeight: 400)
        .sheet(isPresented: $showingAddSymbol) {
            AddSymbolView()
                .environmentObject(appState)
        }
        .sheet(item: $editingSymbol) { symbol in
            EditSymbolView(symbol: symbol)
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
            Text("Drag to reorder. Top symbols appear in menu bar. Tap to edit.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search symbols...", text: $appState.symbolStore.searchText)
                .textFieldStyle(.plain)
            if !appState.symbolStore.searchText.isEmpty {
                Button(action: { appState.symbolStore.searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private var symbolList: some View {
        List {
            ForEach(appState.symbolStore.filteredSymbols) { symbol in
                SymbolListRow(symbol: symbol) {
                    editingSymbol = symbol
                } onDelete: {
                    confirmDelete(symbol)
                }
                .draggable(symbol.id.uuidString) {
                    Text(symbol.ticker)
                        .padding(8)
                        .background(Color.accentColor.opacity(0.2))
                        .cornerRadius(8)
                }
                .dropDestination(for: String.self) { items, location in
                    guard let droppedId = items.first,
                          let droppedUUID = UUID(uuidString: droppedId),
                          let sourceIndex = appState.symbolStore.filteredSymbols.firstIndex(where: { $0.id == droppedUUID }),
                          let destIndex = appState.symbolStore.filteredSymbols.firstIndex(where: { $0.id == symbol.id }) else {
                        return false
                    }
                    if sourceIndex != destIndex {
                        appState.moveSymbols(from: IndexSet(integer: sourceIndex), to: destIndex > sourceIndex ? destIndex + 1 : destIndex)
                    }
                    return true
                }
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

    private var noResultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No results")
                .font(.headline)
            Text("Try a different search term")
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

            Text("\(appState.symbolStore.symbolCount) of 277 symbols")
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
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "line.3.horizontal")
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(symbol.ticker)
                        .fontWeight(.medium)

                    if symbol.hasActiveAlerts {
                        Image(systemName: "bell.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }

                Text(symbol.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 120, alignment: .leading)

            Spacer()

            Text(symbol.type == .crypto ? "Crypto" : "Stock")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 50)

            Text(symbol.exchange.displayName)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(4)
                .frame(width: 100)

            Button(action: onEdit) {
                Image(systemName: "pencil.circle")
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit()
        }
    }
}
