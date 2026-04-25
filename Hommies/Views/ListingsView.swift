import SwiftUI

struct ListingsView: View {
    
    @EnvironmentObject var viewModel: ListingsViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localizationManager: LocalizationManager

    @State private var showFilters = false
    
    let orangeColor = Color(hex: "E8622A")
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // MARK: - Search Bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search rooms, neighborhoods...", text: $viewModel.searchText)
                        .onChange(of: viewModel.searchText) { _, _ in
                            viewModel.applyFilters()
                        }
                    if !viewModel.searchText.isEmpty {
                        Button { viewModel.searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                // MARK: - Room Type Filter Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(["All"] + Listing.roomTypes, id: \.self) { type in
                            FilterChip(
                                title: type,
                                isSelected: viewModel.selectedRoomType == type,
                                color: orangeColor
                            )
                            .onTapGesture {
                                viewModel.selectedRoomType = type
                                viewModel.applyFilters()
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                
                Divider()
                
                // MARK: - Content States
                if viewModel.isLoading {
                    // Loading state — shown while fetching from Firebase
                    Spacer()
                    ProgressView("browse_finding_homes".localized)
                        .foregroundColor(.secondary)
                    Spacer()
                    
                } else if viewModel.filteredListings.isEmpty {
                    // Empty state — no listings match current filters
                    Spacer()
                    VStack(spacing: 16) {
                        Text("🏠")
                            .font(.system(size: 60))
                        Text("browse_no_listings".localized)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("browse_adjust_filters".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button("browse_clear_filters".localized){
                            viewModel.selectedRoomType = "All"
                            viewModel.searchText = ""
                            viewModel.applyFilters()
                        }
                        .foregroundColor(orangeColor)
                    }
                    Spacer()
                    
                } else {
                    // Listings state — shows all matching listings
                    // LazyVStack only renders cards currently visible on screen
                    // Much more memory efficient than VStack for long lists
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.filteredListings) { listing in
                                NavigationLink(destination: ListingDetailView(listing: listing)) {
                                    ListingCardView(listing: listing, viewModel: viewModel)
                                        .padding(.horizontal, 16)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical, 16)
                    }
                    .refreshable {
                        await viewModel.fetchListings()
                    }
                }
            }
            .navigationTitle("browse_title".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // Filter button opens FiltersView as bottom sheet
                    Button {
                        showFilters = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(orangeColor)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text(String(format: "browse_homes_count".localized, viewModel.filteredListings.count))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            // Opens FiltersView as a bottom sheet
            .sheet(isPresented: $showFilters) {
                FiltersView(viewModel: viewModel)
            }
            // Fetch listings from Firebase every time this screen appears
            .onAppear {
                Task {
                    await viewModel.fetchListings()
                }
            }
        }
    }
}
