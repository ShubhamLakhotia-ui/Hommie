//
//  ProfileView.swift
//  Hommies
//
//  Created by Shubham Lakhotia on 4/24/26.
//
import SwiftUI
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

struct ProfileView: View {

    @Binding var selectedTab: Int
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var viewModel: ListingsViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var myListings: [Listing] = []
    @State private var isLoading = false
    @State private var showDeleteAlert = false
    @State private var listingToDelete: Listing? = nil
    @State private var showEditProfile = false
    @State private var showDeleteAccountAlert = false
    @State private var showDeleteErrorAlert = false
    @State private var deleteErrorMessage = ""
    
    let orangeColor = Color(hex: "E8622A")
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    profileHeader
                    statsRow
                    myListingsSection
                    if authViewModel.isAdmin { adminButton }
                    deleteAccountButton
                    signOutButton
                    Spacer().frame(height: 20)
                }
            }
            .navigationTitle("profile_title".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common_edit".localized) { showEditProfile = true }
                        .foregroundColor(orangeColor)
                }
            }
            .onAppear { fetchMyListings() }
            .alert("profile_delete_listing_title".localized, isPresented: $showDeleteAlert) {
                Button("common_delete".localized, role: .destructive) {
                    if let listing = listingToDelete, let id = listing.id {
                        Task {
                            await viewModel.deleteListing(id: id)
                            fetchMyListings()
                        }
                    }
                }
                Button("common_cancel".localized, role: .cancel) {}
            } message: {
                Text("profile_delete_listing_message".localized)
            }
            .alert("profile_delete_account_title".localized, isPresented: $showDeleteAccountAlert) {
                Button("profile_delete_everything".localized, role: .destructive) {
                    Task { await deleteAccount() }
                }
                Button("common_cancel".localized, role: .cancel) {}
            } message: {
                Text("profile_delete_account_message".localized)
            }
            .alert("Error", isPresented: $showDeleteErrorAlert) {
                Button("common_ok".localized, role: .cancel) {}
            } message: {
                Text(deleteErrorMessage)
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(authViewModel: authViewModel)
                    .onDisappear {
                        Task { await authViewModel.fetchUserProfile() }
                    }
            }
        }
    }

    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 12) {
            if let imageURL = authViewModel.currentUser?.profileImageURL,
               !imageURL.isEmpty,
               let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    default:
                        initialsCircle
                    }
                }
            } else {
                initialsCircle
            }
            Text(authViewModel.currentUser?.name ?? "")
                .font(.title2).fontWeight(.bold)
            Text(authViewModel.currentUser?.email ?? "")
                .font(.subheadline).foregroundColor(.secondary)
        }
        .padding(.top, 20)
    }

    private var initialsCircle: some View {
        Circle()
            .fill(orangeColor.opacity(0.15))
            .frame(width: 80, height: 80)
            .overlay(
                Text(String(authViewModel.currentUser?.name.prefix(1) ?? "?"))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(orangeColor)
            )
    }

    // MARK: - Stats Row
    private var statsRow: some View {
        HStack(spacing: 0) {
            StatItem(value: "\(myListings.count)", label: "profile_listings".localized)
            Divider().frame(height: 40)
            StatItem(value: "\(viewModel.favoriteIDs.count)", label: "profile_saved".localized)
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal, 24)
    }

    // MARK: - My Listings Section
    private var myListingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("profile_my_listings".localized)
                    .font(.headline).fontWeight(.semibold)
                Spacer()
                Text(String(format: "profile_total".localized, myListings.count))
                    .font(.caption).foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)

            if isLoading {
                ProgressView().frame(maxWidth: .infinity).padding()
            } else if myListings.isEmpty {
                emptyListingsView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(myListings) { listing in
                        listingRow(listing)
                    }
                }
            }
        }
    }

    private var emptyListingsView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(orangeColor.opacity(0.1)).frame(width: 80, height: 80)
                Image(systemName: "house.badge.plus")
                    .font(.system(size: 36)).foregroundColor(orangeColor)
            }
            VStack(spacing: 6) {
                Text("profile_no_listings".localized)
                    .font(.headline).foregroundColor(.primary)
                Text("profile_no_listings_subtitle".localized)
                    .font(.subheadline).foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button { selectedTab = 2 } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("profile_post_listing".localized).fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 28).padding(.vertical, 14)
                .background(orangeColor).cornerRadius(14)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func listingRow(_ listing: Listing) -> some View {
        NavigationLink(destination: ListingDetailView(listing: listing)) {
            HStack(spacing: 12) {
                listingThumbnail(listing)
                VStack(alignment: .leading, spacing: 4) {
                    Text(listing.title)
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundColor(.primary).lineLimit(1)
                    Text("$\(Int(listing.price))/mo · \(listing.neighborhood)")
                        .font(.caption).foregroundColor(.secondary)
                    Text(listing.roomType)
                        .font(.caption).foregroundColor(orangeColor)
                }
                Spacer()
                HStack(spacing: 4) {
                    NavigationLink(destination: PostListingView(existingListing: listing)
                        .environmentObject(viewModel)
                        .environmentObject(authViewModel)
                        .environmentObject(LocalizationManager.shared)
                    ) {
                        Image(systemName: "pencil")
                            .foregroundColor(orangeColor)
                            .font(.system(size: 16)).padding(8)
                    }
                    Button {
                        listingToDelete = listing
                        showDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .font(.system(size: 16)).padding(8)
                    }
                }
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(14)
            .padding(.horizontal, 24)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func listingThumbnail(_ listing: Listing) -> some View {
        Group {
            if let firstURL = listing.imageURLs.first, let url = URL(string: firstURL) {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFill()
                    } else {
                        Color(.systemGray5)
                    }
                }
                .frame(width: 70, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray5))
                    .frame(width: 70, height: 70)
                    .overlay(Image(systemName: "photo").foregroundColor(.secondary))
            }
        }
    }

    // MARK: - Admin Button
    private var adminButton: some View {
        NavigationLink(destination: AdminView()) {
            HStack {
                Image(systemName: "shield.fill")
                Text("profile_admin_panel".localized).fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity).frame(height: 52)
            .background(Color.purple).cornerRadius(14)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Delete Account Button
    private var deleteAccountButton: some View {
        Button {
            showDeleteAccountAlert = true
        } label: {
            HStack {
                Image(systemName: "person.crop.circle.badge.minus")
                Text("profile_delete_account".localized)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.red.opacity(0.08))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Sign Out Button
    private var signOutButton: some View {
        Button { authViewModel.signOut() } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("profile_sign_out".localized).fontWeight(.semibold)
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity).frame(height: 52)
            .background(Color.red.opacity(0.1)).cornerRadius(14)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Delete Account
    func deleteAccount() async {
        guard let currentUser = Auth.auth().currentUser else { return }
        let uid = currentUser.uid
        let db = Firestore.firestore()
        let storage = Storage.storage()

        do {
            // Steps 1–4 run WHILE the user is still authenticated so Firestore
            // security rules (which check request.auth.uid) can pass.

            // Step 1 — Delete all listings from Firestore
            let listingDocs = try? await db.collection("listings")
                .whereField("ownerId", isEqualTo: uid)
                .getDocuments()
            for doc in listingDocs?.documents ?? [] {
                try? await doc.reference.delete()
            }

            // Step 2 — Delete listing photos from Storage
            let storageRef = storage.reference().child("listings/\(uid)")
            if let items = try? await storageRef.listAll() {
                for item in items.items { try? await item.delete() }
            }

            // Step 3 — Delete profile photo from Storage
            try? await storage.reference().child("profile_images/\(uid).jpg").delete()

            // Step 4 — Delete user document from Firestore
            try await db.collection("users").document(uid).delete()

            // Step 5 — Delete Firebase Auth account LAST.
            // If this fails with requiresRecentLogin (session too old), Firestore
            // data is already gone — the user can sign out, sign back in and tap
            // Delete again; steps 1–4 will be no-ops and step 5 will succeed.
            try await currentUser.delete()

            // Step 6 — Navigate back to WelcomeView
            await MainActor.run {
                authViewModel.currentUser = nil
                authViewModel.isLoggedIn = false
            }

        } catch let error as NSError {
            // AuthErrorCode 17014 = requiresRecentLogin
            let message = error.code == 17014
                ? "For security, please sign out and sign back in, then tap Delete Account again."
                : error.localizedDescription
            await MainActor.run {
                deleteErrorMessage = message
                showDeleteErrorAlert = true
            }
        }
    }

    // MARK: - Fetch My Listings
    func fetchMyListings() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        Task { @MainActor in
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
