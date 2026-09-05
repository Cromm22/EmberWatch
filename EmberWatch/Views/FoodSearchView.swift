import SwiftUI

struct FoodSearchView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var foodDataManager: FoodDataManager
    
    @StateObject private var lookupService = FoodLookupService()
    @StateObject private var searchHistory = SearchHistoryManager()
    @State private var query = ""
    @State private var results: [FoodProduct] = []
    @State private var selectedProduct: FoodProduct?
    @State private var debounceTask: Task<Void, Never>?
    @State private var hasSearched = false
    @State private var lastSearchedQuery = ""
    @State private var isSearchFieldFocused = false
    
    var body: some View {
        NavigationView {
            ZStack {
                EmberColors.dusk.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    searchField
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                    
                    content
                }
            }
            .navigationTitle("Search Foods")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(EmberColors.dusk, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        debounceTask?.cancel()
                        lookupService.cancelSearch()
                        isPresented = false
                    }
                    .foregroundColor(EmberColors.cream)
                }
            }
            .sheet(item: $selectedProduct) { product in
                FoodServingSheet(
                    isPresented: Binding(
                        get: { selectedProduct != nil },
                        set: { if !$0 { selectedProduct = nil } }
                    ),
                    product: product,
                    onConfirm: { entry in
                        foodDataManager.addFoodEntry(entry)
                        selectedProduct = nil
                        isPresented = false
                    }
                )
            }
            .onDisappear {
                debounceTask?.cancel()
                lookupService.cancelSearch()
            }
        }
    }
    
    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(EmberColors.ember)
            
            TextField("Search foods…", text: $query, onEditingChanged: { focused in
                isSearchFieldFocused = focused
            })
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundColor(EmberColors.cream)
                .submitLabel(.search)
                .onSubmit { performSearchNow() }
                .onChange(of: query) { _, newValue in
                    debounceSearch(newValue)
                }
            
            if !query.isEmpty {
                Button {
                    debounceTask?.cancel()
                    lookupService.cancelSearch()
                    query = ""
                    results = []
                    hasSearched = false
                    lastSearchedQuery = ""
                    lookupService.errorMessage = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(EmberColors.cream.opacity(0.5))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(EmberColors.lightPlum)
        )
    }
    
    @ViewBuilder
    private var content: some View {
        if lookupService.isLoading {
            VStack(spacing: 16) {
                ProgressView()
                    .tint(EmberColors.ember)
                    .scaleEffect(1.2)
                Text("Searching…")
                    .foregroundColor(EmberColors.cream.opacity(0.7))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = lookupService.errorMessage, results.isEmpty, hasSearched {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.magnifyingglass")
                    .font(.system(size: 40))
                    .foregroundColor(EmberColors.cream.opacity(0.45))
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(EmberColors.cream.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                HStack(spacing: 12) {
                    Button("Retry") {
                        performSearchNow()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(EmberColors.cream)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(EmberColors.ember))
                    
                    Button("Dismiss") {
                        lookupService.errorMessage = nil
                        hasSearched = false
                        results = []
                    }
                    .foregroundColor(EmberColors.cream.opacity(0.8))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().strokeBorder(EmberColors.cream.opacity(0.35)))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if results.isEmpty {
            // Show search history when no results (read published property — no body side effects)
            if !searchHistory.recentSearches.isEmpty && query.isEmpty {
                searchHistoryView(searchHistory.recentSearches)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "fork.knife.circle")
                        .font(.system(size: 40))
                        .foregroundColor(EmberColors.cream.opacity(0.45))
                    Text(query.trimmingCharacters(in: .whitespaces).count < 2
                         ? "Type at least 2 characters"
                         : "No results yet")
                        .font(.subheadline)
                        .foregroundColor(EmberColors.cream.opacity(0.7))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(results) { product in
                        Button {
                            selectedProduct = product
                        } label: {
                            FoodSearchResultRow(product: product)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
    }
    
    @ViewBuilder
    private func searchHistoryView(_ items: [SearchHistoryItem]) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Recent Searches")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(EmberColors.cream.opacity(0.7))
                    
                    Spacer()
                    
                    Button("Clear") {
                        searchHistory.clearHistory()
                    }
                    .font(.caption)
                    .foregroundColor(EmberColors.ember)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                LazyVStack(spacing: 8) {
                    ForEach(items) { item in
                        Button {
                            query = item.query
                            performSearchNow()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.body)
                                    .foregroundColor(EmberColors.ember.opacity(0.7))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.query)
                                        .font(.body)
                                        .foregroundColor(EmberColors.cream)
                                        .lineLimit(1)
                                    
                                    Text(item.relativeTime)
                                        .font(.caption2)
                                        .foregroundColor(EmberColors.cream.opacity(0.5))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "arrow.up.left")
                                    .font(.caption)
                                    .foregroundColor(EmberColors.cream.opacity(0.35))
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(EmberColors.lightPlum)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
    }
    
    private func debounceSearch(_ value: String) {
        debounceTask?.cancel()
        lookupService.cancelSearch()
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            await runSearch(value)
        }
    }
    
    private func performSearchNow() {
        debounceTask?.cancel()
        lookupService.cancelSearch()
        let q = query.isEmpty ? lastSearchedQuery : query
        Task { await runSearch(q) }
    }
    
    @MainActor
    private func runSearch(_ value: String) async {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            results = []
            hasSearched = false
            lastSearchedQuery = ""
            lookupService.errorMessage = nil
            lookupService.isLoading = false
            return
        }
        hasSearched = true
        lastSearchedQuery = trimmed
        
        // Add to search history
        searchHistory.addSearch(trimmed)
        
        // Keep previous results until new ones arrive so we never flash a blank white screen.
        let found = await lookupService.searchFoods(query: trimmed)
        // Ignore stale completions after cancel / newer keystroke.
        guard !Task.isCancelled else { return }
        guard lastSearchedQuery == trimmed else { return }
        results = found
    }
}

struct FoodSearchResultRow: View {
    let product: FoodProduct
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "leaf.fill")
                .font(.title3)
                .foregroundColor(EmberColors.ember)
                .frame(width: 40, height: 40)
                .background(Circle().fill(EmberColors.dusk))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.headline)
                    .foregroundColor(EmberColors.cream)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(product.servingSize)
                    .font(.caption)
                    .foregroundColor(EmberColors.cream.opacity(0.55))
            }
            
            Spacer(minLength: 8)
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(product.caloriesPerServing))")
                    .font(.headline)
                    .foregroundColor(EmberColors.ember)
                Text("cal")
                    .font(.caption2)
                    .foregroundColor(EmberColors.cream.opacity(0.55))
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(EmberColors.cream.opacity(0.35))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(EmberColors.lightPlum)
        )
    }
}
