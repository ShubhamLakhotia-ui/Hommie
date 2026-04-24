//
//  ListingService.swift
//  Hommies
//
//  Created by Shubham Lakhotia on 4/22/26.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage
import UIKit

class ListingService{
    
    static let shared = ListingService()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    // MARK: - Fetch All Listings
       // Fetches all listings from Firestore ordered by newest first
       func fetchListings() async throws -> [Listing] {
           let snapshot = try await db.collection("listings")
               .order(by: "createdAt", descending: true)
               .getDocuments()
           
           // compactMap converts each document to a Listing
           // compactMap skips any documents that fail to decode
           return snapshot.documents.compactMap { doc in
               guard let listing = try? doc.data(as: Listing.self) else { return nil }
               // Auto-hide listings with 3+ reports
               if let reportCount = listing.reportCount, reportCount >= 3 {
                   return nil
               }
               return listing
           }
       }
    
    // MARK: - Fetch Listings by Owner
        // Used on Profile screen to show user's own listings
        func fetchListings(for ownerId: String) async throws -> [Listing] {
            let snapshot = try await db.collection("listings")
                .whereField("ownerId", isEqualTo: ownerId)
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            return snapshot.documents.compactMap { doc in
                try? doc.data(as: Listing.self)
            }
        }
    func postListing(listing: Listing, images: [UIImage]) async throws {
        
        var imageURLs: [String] = []
        
        for (index, image) in images.enumerated() {
            let url = try await uploadImage(
                image,
                path: "listings/\(listing.ownerId)/\(UUID().uuidString)_\(index).jpg"
            )
            imageURLs.append(url)
        }
        
        var listingWithImages = listing
        listingWithImages.imageURLs = imageURLs
        
        try db.collection("listings").addDocument(from: listingWithImages)
    }
    
    func deleteListing(id: String) async throws {
           try await db.collection("listings").document(id).delete()
       }
    
    private func uploadImage(_ image: UIImage, path: String) async throws -> String {
            
            // Compress image to JPEG at 80% quality
            // Reduces file size without noticeable quality loss
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                throw NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
            }
            
            let storageRef = storage.reference().child(path)
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
  
            _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
            
            // After upload get the public download URL
            let downloadURL = try await storageRef.downloadURL()
            return downloadURL.absoluteString
        }
    
    // MARK: - Search & Filter Listings
    func filterListings(_ listings: [Listing],
                           searchText: String,
                           minPrice: Double,
                           maxPrice: Double,
                           roomType: String,
                           furnished: Bool?,
                           petsAllowed: Bool?) -> [Listing] {
            
            return listings.filter { listing in
                
            
                let matchesSearch = searchText.isEmpty ||
                    listing.title.localizedCaseInsensitiveContains(searchText) ||
                    listing.description.localizedCaseInsensitiveContains(searchText) ||
                    listing.neighborhood.localizedCaseInsensitiveContains(searchText)
                
                // Price range filter
                let matchesPrice = listing.price >= minPrice && listing.price <= maxPrice
                
                // Room type filter — "All" means no filter applied
                let matchesRoomType = roomType == "All" || listing.roomType == roomType
                
                // Furnished filter — nil means no filter applied
                let matchesFurnished = furnished == nil || listing.furnished == furnished
                
                // Pets filter — nil means no filter applied
                let matchesPets = petsAllowed == nil || listing.petsAllowed == petsAllowed
                
                return matchesSearch && matchesPrice && matchesRoomType && matchesFurnished && matchesPets
            }
        }
    }

    
