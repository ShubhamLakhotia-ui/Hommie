import SwiftUI

struct ListingsView: View {
    
    @EnvironmentObject var viewModel: ListingsViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var showFilters = false
    
    let orangeColor = Color(hex: "E8622A")
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // MARK: - Room Type Filter Chips
                // Horizontal scrolling chips for quick room type filtering
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
                    ProgressView("Finding homes...")
                        .foregroundColor(.secondary)
                    Spacer()
                    
                } else if viewModel.filteredListings.isEmpty {
                    // Empty state — no listings match current filters
                    Spacer()
                    VStack(spacing: 16) {
                        Text("🏠")
                            .font(.system(size: 60))
                        Text("No listings found")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Try adjusting your filters")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button("Clear Filters") {
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
                                // NavigationLink pushes ListingDetailView when card is tapped
                                NavigationLink(destination: ListingDetailView(listing: listing)) {
                                    ListingCardView(listing: listing, viewModel: viewModel)
                                        .padding(.horizontal, 16)
                                }
                                // PlainButtonStyle removes default blue tint from NavigationLink
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("Hommies")
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
                    Text("\(viewModel.filteredListings.count) homes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            // .searchable adds iOS native search bar to navigation bar
            // Handles clear button, cancel button, keyboard dismiss automatically
            .searchable(text: $viewModel.searchText, prompt: "Search rooms, neighborhoods...")
            // Fires applyFilters every time user types a character
            .onChange(of: viewModel.searchText) { _, _ in
                viewModel.applyFilters()
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
