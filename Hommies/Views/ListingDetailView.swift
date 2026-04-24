//
//  ListingDetailView.swift
//  Hommies
//
//  Created by Shubham Lakhotia on 4/23/26.
//
import SwiftUI
import MapKit
import CoreLocation
import FirebaseFirestore
import FirebaseAuth

struct ListingDetailView: View {
    
    let listing: Listing
    @EnvironmentObject var viewModel: ListingsViewModel
    @Environment(\.dismiss) var dismiss
    @StateObject private var detailViewModel = ListingDetailViewModel()
    @State private var showReportAlert = false
    @State private var reportSubmitted = false
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
                    
                    // Show warning if listing is older than 30 days
                    if Date().timeIntervalSince(listing.createdAt) > 60 * 60 * 24 * 30 {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("This listing is over 30 days old — verify details before contacting")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(10)
                        
                        Divider()
                    }
                    
                    // Warning badge — shows if listing has 1-2 reports
                    // At 3+ reports listing is hidden completely from browse screen
                    if let reportCount = listing.reportCount, reportCount > 0 && reportCount < 3 {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.shield.fill")
                                .foregroundColor(.red)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Flagged by \(reportCount) user\(reportCount > 1 ? "s" : "")")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.red)
                                Text("This listing has been reported. Verify details carefully before contacting.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(12)
                        .background(Color.red.opacity(0.08))
                        .cornerRadius(10)
                        
                        Divider()
                    }
                    
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
                    
                    // MARK: - Safety Score
                    // Only shows if listing has coordinates
                    if let lat = listing.latitude, let lon = listing.longitude,
                       lat != 0.0 && lon != 0.0 {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Area Safety")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            if detailViewModel.isLoadingCrime {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Checking safety data...")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            } else if !detailViewModel.safetyScore.isEmpty {
                                HStack(spacing: 12) {
                                    // Safety icon changes based on score
                                    Circle()
                                        .fill(safetyColor(for: detailViewModel.safetyScore).opacity(0.15))
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Image(systemName: safetyIcon(for: detailViewModel.safetyScore))
                                                .foregroundColor(safetyColor(for: detailViewModel.safetyScore))
                                                .font(.system(size: 18))
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(detailViewModel.safetyScore)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(safetyColor(for: detailViewModel.safetyScore))
                                        Text("Based on nearby crime incidents")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                            } else if !detailViewModel.crimeError.isEmpty {
                                Text(detailViewModel.crimeError)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    // MARK: - MBTA Transit
                    if let lat = listing.latitude, let lon = listing.longitude,
                       lat != 0.0 && lon != 0.0 {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Nearby Transit")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            if detailViewModel.isLoadingMBTA {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Loading transit stops...")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            } else if detailViewModel.mbtaStops.isEmpty {
                                Text(detailViewModel.mbtaError.isEmpty ? "No transit stops nearby" : detailViewModel.mbtaError)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            } else {
                                VStack(spacing: 8) {
                                    ForEach(detailViewModel.mbtaStops.prefix(5)) { stop in
                                        HStack(spacing: 12) {
                                            // Transit icon with line color
                                            Circle()
                                                .fill(Color(hex: stop.attributes.lineColor).opacity(0.15))
                                                .frame(width: 36, height: 36)
                                                .overlay(
                                                    Image(systemName: stop.attributes.icon)
                                                        .foregroundColor(Color(hex: stop.attributes.lineColor))
                                                        .font(.system(size: 14))
                                                )
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(stop.attributes.name)
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.primary)
                                                Text(stop.attributes.transitType)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                        }
                                        .padding(10)
                                        .background(Color(.secondarySystemBackground))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }
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
        }.toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showReportAlert = true
                } label: {
                    Image(systemName: "flag")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle(listing.title)
        .navigationBarTitleDisplayMode(.inline)
        .ignoresSafeArea(edges: .top)
        .alert("Report Listing", isPresented: $showReportAlert) {
            Button("Fake or Scam", role: .destructive) {
                reportListing(reason: "Fake or Scam")
            }
            Button("Inappropriate Content", role: .destructive) {
                reportListing(reason: "Inappropriate Content")
            }
            Button("Wrong Information", role: .destructive) {
                reportListing(reason: "Wrong Information")
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Why are you reporting this listing?")
        }
        .alert("Report Submitted", isPresented: $reportSubmitted) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Thank you for helping keep Hommies safe. We'll review this listing.")
        }
        .task {
            await detailViewModel.fetchData(listing: listing)
        }
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
    
    func reportListing(reason: String) {
        guard let id = listing.id,
              let uid = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        
        let report: [String: Any] = [
            "listingId": id,
            "listingTitle": listing.title,
            "reportedBy": uid,
            "reason": reason,
            "createdAt": Timestamp(date: Date())
        ]
        
        db.collection("reports").addDocument(data: report) { error in
            if error == nil {
                // FieldValue.increment atomically adds 1
                // Safe even if multiple users report at same time
                db.collection("listings").document(id).updateData([
                    "reportCount": FieldValue.increment(Int64(1))
                ])
                reportSubmitted = true
            }
        }
    }
    // MARK: - Safety Color
    func safetyColor(for score: String) -> Color {
        switch score {
        case "Very Safe": return .green
        case "Generally Safe": return Color(hex: "00843D")
        case "Moderate": return .orange
        case "Use Caution": return .red
        default: return .red
        }
    }

    // MARK: - Safety Icon
    func safetyIcon(for score: String) -> String {
        switch score {
        case "Very Safe": return "checkmark.shield.fill"
        case "Generally Safe": return "checkmark.shield.fill"
        case "Moderate": return "exclamationmark.shield.fill"
        case "Use Caution": return "xmark.shield.fill"
        default: return "xmark.shield.fill"
        }
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
