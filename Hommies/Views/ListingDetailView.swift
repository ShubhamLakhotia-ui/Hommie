//
//  ListingDetailView.swift
//  Hommies
//
//  Created by Shubham Lakhotia on 4/23/26.
//
import SwiftUI
import MapKit
import CoreLocation

struct ListingDetailView: View {
    
    let listing: Listing
    @EnvironmentObject var viewModel: ListingsViewModel
    @Environment(\.dismiss) var dismiss
    
    let orangeColor = Color(hex: "E8622A")
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                
                // MARK: - Photo Gallery
                if listing.imageURLs.isEmpty {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 300)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                Text("No Photos")
                                    .foregroundColor(.secondary)
                            }
                        )
                } else {
                    TabView {
                        ForEach(listing.imageURLs, id: \.self) { urlString in
                            AsyncImage(url: URL(string: urlString)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 300)
                                        .clipped()
                                case .failure:
                                    Rectangle()
                                        .fill(Color(.systemGray5))
                                        .frame(height: 300)
                                case .empty:
                                    Rectangle()
                                        .fill(Color(.systemGray5))
                                        .frame(height: 300)
                                        .overlay(ProgressView())
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                    }
                    .tabViewStyle(.page)
                    .frame(height: 300)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    
                    // MARK: - Price + Favorite
                    HStack {
                        Text("$\(Int(listing.price))/mo")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(orangeColor)
                        Spacer()
                        Button {
                            if let id = listing.id {
                                viewModel.toggleFavorite(listingID: id)
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color(.secondarySystemBackground))
                                    .frame(width: 44, height: 44)
                                Image(systemName: viewModel.isFavorite(listingID: listing.id ?? "") ? "heart.fill" : "heart")
                                    .font(.system(size: 20))
                                    .foregroundColor(viewModel.isFavorite(listingID: listing.id ?? "") ? .red : .gray)
                            }
                        }
                    }
                    
                    // MARK: - Title + Badges
                    VStack(alignment: .leading, spacing: 8) {
                        Text(listing.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 8) {
                            Text(listing.roomType)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(orangeColor)
                                .cornerRadius(20)
                            
                            // Distance badge — shows campus name if available
                            HStack(spacing: 4) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(orangeColor)
                                Text(listing.campusName.map {
                                    "\(listing.distanceToCampus) from \($0)"
                                } ?? listing.distanceToCampus)
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                    
                    // MARK: - Neighborhood
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .foregroundColor(orangeColor)
                        Text(listing.neighborhood)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // MARK: - Key Details Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        DetailItem(icon: "calendar", title: "Available from", value: listing.availableFrom.formatted(.dateTime.month(.abbreviated).day().year()))
                        DetailItem(icon: "calendar.badge.checkmark", title: "Available to", value: listing.availableTo.formatted(.dateTime.month(.abbreviated).day().year()))
                        DetailItem(icon: "person.2.fill", title: "Roommates", value: "\(listing.roommates)")
                        DetailItem(icon: "dollarsign.circle.fill", title: "Monthly rent", value: "$\(Int(listing.price))")
                        DetailItem(icon: "sofa.fill", title: "Furnished", value: listing.furnished ? "Yes" : "No")
                        DetailItem(icon: "pawprint.fill", title: "Pets allowed", value: listing.petsAllowed ? "Yes" : "No")
                        DetailItem(icon: "bolt.fill", title: "Utilities", value: listing.utilitiesIncluded ? "Included" : "Not included")
                    }
                    
                    Divider()
                    
                    // MARK: - Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About this place")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text(listing.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    
                    Divider()
                    
                    // MARK: - Location Map
                    // Only shows if listing has valid coordinates
                    if let lat = listing.latitude, let lon = listing.longitude,
                       lat != 0.0 && lon != 0.0 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Location")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Button {
                                openInMaps(lat: lat, lon: lon)
                            } label: {
                                ZStack(alignment: .bottomTrailing) {
                                    Map(coordinateRegion: .constant(
                                        MKCoordinateRegion(
                                            center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                        )
                                    ), annotationItems: [PinLocation(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))]) { pin in
                                        MapAnnotation(coordinate: pin.coordinate) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color(hex: "E8622A"))
                                                    .frame(width: 32, height: 32)
                                                Image(systemName: "house.fill")
                                                    .foregroundColor(.white)
                                                    .font(.system(size: 14))
                                            }
                                        }
                                    }
                                    .frame(height: 200)
                                    .cornerRadius(16)
                                    .disabled(true)
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: "map.fill")
                                            .font(.system(size: 11))
                                        Text("Open in Maps")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(20)
                                    .padding(10)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // MARK: - Campus Distance
                            // Shows which campus the poster selected and distance
                            if let campusName = listing.campusName,
                               !campusName.isEmpty,
                               !listing.distanceToCampus.isEmpty {
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(Color.blue.opacity(0.1))
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Image(systemName: "building.columns.fill")
                                                .foregroundColor(.blue)
                                                .font(.system(size: 14))
                                        )
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(campusName)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Text(listing.distanceToCampus)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                            }
                        }
                        
                        Divider()
                    }
                    
                    // MARK: - Posted By
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Posted by")
                            .font(.headline)
                            .fontWeight(.semibold)
                        HStack(spacing: 12) {
                            Circle()
                                .fill(orangeColor.opacity(0.15))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Text(String(listing.ownerName.prefix(1)))
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(orangeColor)
                                )
                            VStack(alignment: .leading, spacing: 2) {
                                Text(listing.ownerName)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text(listing.contactEmail)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // MARK: - Contact Buttons
                    VStack(spacing: 12) {
                        Link(destination: URL(string: "mailto:\(listing.contactEmail)")!) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                Text("Email Poster")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(orangeColor)
                            .cornerRadius(14)
                        }
                        
                        if !listing.contactPhone.isEmpty {
                            Link(destination: URL(string: "tel:\(listing.contactPhone)")!) {
                                HStack {
                                    Image(systemName: "phone.fill")
                                    Text("Call Poster")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(orangeColor)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(orangeColor, lineWidth: 1)
                                )
                            }
                        }
                    }
                    
                    Spacer().frame(height: 20)
                }
                .padding(16)
            }
        }
        .navigationTitle(listing.title)
        .navigationBarTitleDisplayMode(.inline)
        .ignoresSafeArea(edges: .top)
    }
    
    func openInMaps(lat: Double, lon: Double) {
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = listing.title
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: coordinate),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        ])
    }
}

// MARK: - Detail Item
struct DetailItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(Color(hex: "E8622A"))
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
