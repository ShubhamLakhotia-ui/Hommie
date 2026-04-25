//
//  FavoritesView.swift
//  Hommies
//
//  Created by Shubham Lakhotia on 4/24/26.
//

import SwiftUI

struct FavoritesView: View {

    @EnvironmentObject var viewModel: ListingsViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    let orangeColor = Color(hex: "E8622A")

    // Snapshot of favorites taken when the tab appears — prevents the empty-state
    // flash that happens when fetchListings() replaces the listings array mid-render.
    @State private var stableFavorites: [Listing] = []

    var body: some View {
        NavigationStack {
            Group {
                if stableFavorites.isEmpty && !viewModel.isLoading {
                    // Empty state — only shown when we're sure there are no favorites
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "heart.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("favorites_empty".localized)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("favorites_empty_subtitle".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(stableFavorites) { listing in
                                NavigationLink(destination: ListingDetailView(listing: listing)) {
                                    ListingCardView(listing: listing, viewModel: viewModel)
                                        .padding(.horizontal, 16)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("favorites_title".localized)
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                // Reload favorites for the current user (handles account switching)
                viewModel.loadFavorites()
                // Capture favorites before the fetch so AsyncImage never loses
                // its position — the stable snapshot is updated AFTER fetch completes.
                if !viewModel.favoriteListings.isEmpty {
                    stableFavorites = viewModel.favoriteListings
                }
                Task {
                    await viewModel.fetchListings()
                    // Update snapshot once fresh data has arrived
                    stableFavorites = viewModel.favoriteListings
                }
            }
            .toolbar {
                if !stableFavorites.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Text("\(stableFavorites.count) saved")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}
