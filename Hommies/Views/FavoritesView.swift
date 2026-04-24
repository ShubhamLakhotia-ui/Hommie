//
//  FavoritesView.swift
//  Hommies
//
//  Created by Shubham Lakhotia on 4/24/26.
//

import SwiftUI

struct FavoritesView: View {
    
    @EnvironmentObject var viewModel: ListingsViewModel
    let orangeColor = Color(hex: "E8622A")
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.favoriteListings.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "heart.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No saved listings")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Tap the heart on any listing to save it here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.favoriteListings) { listing in
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
            .navigationTitle("Saved")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !viewModel.favoriteListings.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Text("\(viewModel.favoriteListings.count) saved")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}
