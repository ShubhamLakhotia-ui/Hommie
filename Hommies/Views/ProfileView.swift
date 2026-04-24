//
//  ProfileView.swift
//  Hommies
//
//  Created by Shubham Lakhotia on 4/24/26.
//
import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var viewModel: ListingsViewModel
    @State private var myListings: [Listing] = []
    @State private var isLoading = false
    @State private var showDeleteAlert = false
    @State private var listingToDelete: Listing? = nil
    
    let orangeColor = Color(hex: "E8622A")
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: - Profile Header
                    VStack(spacing: 12) {
                        Circle()
                            .fill(orangeColor.opacity(0.15))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text(String(authViewModel.currentUser?.name.prefix(1) ?? "?"))
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(orangeColor)
                            )
                        
                        Text(authViewModel.currentUser?.name ?? "")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(authViewModel.currentUser?.email ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // MARK: - Stats Row
                    HStack(spacing: 0) {
                        StatItem(value: "\(myListings.count)", label: "Listings")
                        Divider().frame(height: 40)
                        StatItem(value: "\(viewModel.favoriteIDs.count)", label: "Saved")
                    }
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal, 24)
                    
                    // MARK: - My Listings
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("My Listings")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("\(myListings.count) total")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 24)
                        
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if myListings.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "house")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                Text("No listings yet")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("Tap Post to add your first listing")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(40)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(myListings) { listing in
                                    NavigationLink(destination: ListingDetailView(listing: listing)) {
                                        HStack(spacing: 12) {
                                            // Thumbnail
                                            if let firstURL = listing.imageURLs.first,
                                               let url = URL(string: firstURL) {
                                                AsyncImage(url: url) { phase in
                                                    switch phase {
                                                    case .success(let image):
                                                        image
                                                            .resizable()
                                                            .scaledToFill()
                                                            .frame(width: 70, height: 70)
                                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                                    default:
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .fill(Color(.systemGray5))
                                                            .frame(width: 70, height: 70)
                                                    }
                                                }
                                            } else {
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(Color(.systemGray5))
                                                    .frame(width: 70, height: 70)
                                                    .overlay(
                                                        Image(systemName: "photo")
                                                            .foregroundColor(.secondary)
                                                    )
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(listing.title)
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.primary)
                                                    .lineLimit(1)
                                                Text("$\(Int(listing.price))/mo · \(listing.neighborhood)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                Text(listing.roomType)
                                                    .font(.caption)
                                                    .foregroundColor(orangeColor)
                                            }
                                            
                                            Spacer()
                                            
                                            // Delete button
                                            Button {
                                                listingToDelete = listing
                                                showDeleteAlert = true
                                            } label: {
                                                Image(systemName: "trash")
                                                    .foregroundColor(.red)
                                                    .font(.system(size: 16))
                                                    .padding(8)
                                            }
                                        }
                                        .padding(12)
                                        .background(Color(.secondarySystemBackground))
                                        .cornerRadius(14)
                                        .padding(.horizontal, 24)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                    
                    // Admin Panel — only visible to admin users
                    if authViewModel.isAdmin {
                        NavigationLink(destination: AdminView()) {
                            HStack {
                                Image(systemName: "shield.fill")
                                Text("Admin Panel")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.purple)
                            .cornerRadius(14)
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    
                    
                    // MARK: - Sign Out
                    Button {
                        authViewModel.signOut()
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(14)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer().frame(height: 20)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                fetchMyListings()
            }
            .alert("Delete Listing", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let listing = listingToDelete, let id = listing.id {
                        Task {
                            await viewModel.deleteListing(id: id)
                            fetchMyListings()
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete \"\(listingToDelete?.title ?? "")\"? This cannot be undone.")
            }
        }
    }
    
    func fetchMyListings() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        Task {
            do {
                myListings = try await ListingService.shared.fetchListings(for: uid)
            } catch {
                print("Error fetching my listings: \(error)")
            }
            isLoading = false
        }
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "E8622A"))
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}
