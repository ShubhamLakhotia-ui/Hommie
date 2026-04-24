import Foundation
import UIKit
import Combine

class ListingsViewModel: ObservableObject {
    
    @Published var listings: [Listing] = []
    @Published var filteredListings: [Listing] = []
    @Published var favoriteIDs: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var postSuccess = false
    
    @Published var searchText = ""
    @Published var minPrice: Double = 0
    @Published var maxPrice: Double = 5000
    @Published var selectedRoomType = "All"
    @Published var furnishedFilter: Bool? = nil
    @Published var petsFilter: Bool? = nil
    
    private let listingService = ListingService.shared
    private let favoritesKey = "hommies_favorites"
    
    init() {
        loadFavorites()
    }
    
    // MARK: - Fetch Listings
    @MainActor
    func fetchListings() async {
        isLoading = true
        errorMessage = ""
        do {
            listings = try await listingService.fetchListings()
            applyFilters()
        } catch {
            errorMessage = "Failed to load listings. Please try again."
        }
        isLoading = false
    }
    
    // MARK: - Post Listing
    @MainActor
    func postListing(listing: Listing, images: [UIImage]) async {
        isLoading = true
        errorMessage = ""
        postSuccess = false
        do {
            try await listingService.postListing(listing: listing, images: images)
            postSuccess = true
            await fetchListings()
        } catch {
            errorMessage = "Failed to post listing. Please try again."
        }
        isLoading = false
    }
    
    // MARK: - Delete Listing
    @MainActor
    func deleteListing(id: String) async {
        do {
            try await listingService.deleteListing(id: id)
            listings.removeAll { $0.id == id }
            applyFilters()
        } catch {
            errorMessage = "Failed to delete listing."
        }
    }
    
    // MARK: - Apply Filters
    // @MainActor because it updates @Published filteredListings → drives UI
    @MainActor
    func applyFilters() {
        filteredListings = listingService.filterListings(
            listings,
            searchText: searchText,
            minPrice: minPrice,
            maxPrice: maxPrice,
            roomType: selectedRoomType,
            furnished: furnishedFilter,
            petsAllowed: petsFilter
        )
    }
    
    // MARK: - Favorites
    // @MainActor because it updates @Published favoriteIDs → drives heart icons in UI
    @MainActor
    func toggleFavorite(listingID: String) {
        if isFavorite(listingID: listingID) {
            favoriteIDs.remove(listingID)
        } else {
            favoriteIDs.insert(listingID)
        }
        saveFavorites()
    }
    
    func isFavorite(listingID: String) -> Bool {
        return favoriteIDs.contains(listingID)
    }
    
    private func saveFavorites() {
        UserDefaults.standard.set(Array(favoriteIDs), forKey: favoritesKey)
    }
    
    private func loadFavorites() {
        let saved = UserDefaults.standard.stringArray(forKey: favoritesKey) ?? []
        favoriteIDs = Set(saved)
    }
    
    // Returns only favorited listings — used on Favorites screen
    var favoriteListings: [Listing] {
        listings.filter { listing in
            guard let id = listing.id else { return false }
            return isFavorite(listingID: id)
        }
    }
}
