//
//  ListingDetailViewModel.swift
//  Hommies
//
//  Created by Shubham Lakhotia on 4/24/26.
//

import Foundation
import SwiftUI
import Combine

// ViewModel specifically for ListingDetailView
// Handles MBTA and Crime API calls with loading states
class ListingDetailViewModel: ObservableObject {
    
    @Published var mbtaStops: [MBTAStop] = []
    @Published var safetyScore: String = ""
    @Published var isLoadingMBTA = false
    @Published var isLoadingCrime = false
    @Published var mbtaError = ""
    @Published var crimeError = ""
    
    private let apiService = APIService.shared
    
    // MARK: - Fetch All Data
    // Called once when detail screen opens
    // Uses listing ID as cache key — won't hit API twice for same listing
    @MainActor
    func fetchData(listing: Listing) async {
        guard let id = listing.id,
              let lat = listing.latitude,
              let lon = listing.longitude,
              lat != 0.0 && lon != 0.0 else {
            // No coordinates — can't fetch location based data
            return
        }
        
        // Fetch MBTA and Crime concurrently using async let
        // Both API calls happen at the same time — faster than sequential
        async let mbtaFetch = fetchMBTA(listingID: id, lat: lat, lon: lon)
        async let crimeFetch = fetchCrime(listingID: id, lat: lat, lon: lon)
        
        // Wait for both to complete
        await mbtaFetch
        await crimeFetch
    }
    
    // MARK: - Fetch MBTA
    @MainActor
    private func fetchMBTA(listingID: String, lat: Double, lon: Double) async {
        isLoadingMBTA = true
        mbtaError = ""
        do {
            mbtaStops = try await apiService.fetchNearbyStops(
                listingID: listingID,
                latitude: lat,
                longitude: lon
            )
        } catch {
            mbtaError = "Could not load transit data"
        }
        isLoadingMBTA = false
    }
    
    // MARK: - Fetch Crime
    @MainActor
    private func fetchCrime(listingID: String, lat: Double, lon: Double) async {
        isLoadingCrime = true
        crimeError = ""
        do {
            safetyScore = try await apiService.fetchCrimeData(
                listingID: listingID,
                latitude: lat,
                longitude: lon
            )
        } catch {
            crimeError = "Could not load safety data"
        }
        isLoadingCrime = false
    }
}
