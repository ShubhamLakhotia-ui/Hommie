import SwiftUI

// Reusable card component shown in the listings list
// Displays key info about a listing at a glance
struct ListingCardView: View {
    
    let listing: Listing
    // ObservedObject receives ViewModel from parent — doesn't own it
    @ObservedObject var viewModel: ListingsViewModel
    
    let orangeColor = Color(hex: "E8622A")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // MARK: - Photo Section
            ZStack(alignment: .topTrailing) {
                
                if let firstImageURL = listing.imageURLs.first,
                   let url = URL(string: firstImageURL) {
                    // AsyncImage loads images from URL asynchronously
                    // No third party library needed — built into SwiftUI
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .clipped()
                        case .failure:
                            // Show placeholder if image fails to load
                            placeholderImage
                        case .empty:
                            // Show shimmer while loading
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .frame(height: 200)
                                .overlay(ProgressView())
                        @unknown default:
                            placeholderImage
                        }
                    }
                } else {
                    placeholderImage
                }
                
                // MARK: - Favorite Button
                Button {
                    if let id = listing.id {
                        viewModel.toggleFavorite(listingID: id)
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.9))
                            .frame(width: 36, height: 36)
                        Image(systemName: viewModel.isFavorite(listingID: listing.id ?? "")
                              ? "heart.fill" : "heart")
                            .font(.system(size: 16))
                            .foregroundColor(viewModel.isFavorite(listingID: listing.id ?? "")
                                             ? .red : .gray)
                    }
                }
                .padding(12)
                
                // MARK: - Room Type Badge
                VStack {
                    Spacer()
                    HStack {
                        Text(listing.roomType)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(orangeColor)
                            .cornerRadius(20)
                            .padding(12)
                        Spacer()
                    }
                }
                .frame(height: 200)
            }
            .frame(height: 200)
            .clipped()
            
            // MARK: - Info Section
            VStack(alignment: .leading, spacing: 8) {
                
                // Price + Distance row
                HStack {
                    Text("$\(Int(listing.price))/mo")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(orangeColor)
                    
                    Spacer()
                    
                    // Distance to campus
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        Text(listing.distanceToCampus)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Listing title
                Text(listing.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    // lineLimit prevents long titles from expanding the card
                    .lineLimit(1)
                
                // Neighborhood
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(listing.neighborhood)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // MARK: - Feature Pills
                HStack(spacing: 8) {
                    if listing.furnished {
                        FeaturePill(icon: "sofa.fill", text: "Furnished")
                    }
                    if listing.petsAllowed {
                        FeaturePill(icon: "pawprint.fill", text: "Pets OK")
                    }
                    if listing.utilitiesIncluded {
                        FeaturePill(icon: "bolt.fill", text: "Utilities")
                    }
                }
                
                // Available dates
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(listing.availableFrom.formatted(.dateTime.month(.abbreviated).day())) - \(listing.availableTo.formatted(.dateTime.month(.abbreviated).day().year()))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(14)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
    
    // Placeholder shown when no image or image fails to load
    var placeholderImage: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .frame(height: 200)
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No Photo")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            )
    }
}

// MARK: - Feature Pill
// Small pill showing a listing feature like Furnished, Pets OK
struct FeaturePill: View {
    
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(Color(hex: "E8622A"))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(hex: "E8622A").opacity(0.1))
        .cornerRadius(20)
    }
}
