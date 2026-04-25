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
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) var dismiss
    @StateObject private var detailViewModel = ListingDetailViewModel()
    @State private var showReportAlert = false
    @State private var reportSubmitted = false
    @State private var alreadyReported = false
    let orangeColor = Color(hex: "E8622A")

    var shareText: String {
        var lines = ["🏠 \(listing.title)", "📍 \(listing.neighborhood)", "💰 $\(Int(listing.price))/month"]
        var features: [String] = []
        if listing.furnished { features.append("Furnished") }
        if listing.petsAllowed { features.append("Pets allowed") }
        if listing.utilitiesIncluded { features.append("Utilities included") }
        if !features.isEmpty { lines.append("✅ \(features.joined(separator: " • "))") }
        if let campus = listing.campusName { lines.append("🎓 Near \(campus)") }
        lines.append("📧 \(listing.contactEmail)")
        lines.append("\nFound on Hommies app")
        return lines.joined(separator: "\n")
    }
    
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
                                Text("detail_no_photos".localized)
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
                        DetailItem(icon: "calendar", title: "detail_available_from".localized, value: listing.availableFrom.formatted(.dateTime.month(.abbreviated).day().year()))
                        DetailItem(icon: "calendar.badge.checkmark", title: "detail_available_to".localized, value: listing.availableTo.formatted(.dateTime.month(.abbreviated).day().year()))
                        DetailItem(icon: "person.2.fill", title: "detail_roommates".localized, value: "\(listing.roommates)")
                        DetailItem(icon: "dollarsign.circle.fill", title: "detail_monthly_rent".localized, value: "$\(Int(listing.price))")
                        DetailItem(icon: "sofa.fill", title: "detail_furnished_label".localized, value: listing.furnished ? "common_yes".localized : "common_no".localized)
                        DetailItem(icon: "pawprint.fill", title: "detail_pets_label".localized, value: listing.petsAllowed ? "common_yes".localized : "common_no".localized)
                        DetailItem(icon: "bolt.fill", title: "detail_utilities_label".localized, value: listing.utilitiesIncluded ? "detail_included".localized : "detail_not_included".localized)
                    }
                    
                    Divider()
                    
                    // Show warning if listing is older than 30 days
                    if Date().timeIntervalSince(listing.createdAt) > 60 * 60 * 24 * 30 {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("detail_stale_warning".localized)
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
                                Text(String(format: "detail_flagged_by".localized, reportCount))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.red)
                                Text("detail_flagged_message".localized)
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
                        Text("detail_about".localized)
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
                            Text("detail_location".localized)
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
                                        Text("detail_open_in_maps".localized)
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
                            Text("detail_area_safety".localized)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            if detailViewModel.isLoadingCrime {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("detail_checking_safety".localized)
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
                                        Text(localizedSafetyScore(detailViewModel.safetyScore))
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(safetyColor(for: detailViewModel.safetyScore))
                                        Text("detail_crime_basis".localized)
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
                            Text("detail_nearby_transit".localized)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            if detailViewModel.isLoadingMBTA {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("detail_loading_transit".localized)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            } else if detailViewModel.mbtaStops.isEmpty {
                                Text(detailViewModel.mbtaError.isEmpty ? "detail_no_transit".localized : detailViewModel.mbtaError)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            } else {
                                VStack(spacing: 8) {
                                    ForEach(detailViewModel.mbtaStops.prefix(5)) { stop in
                                        let color = stop.attributes.lineColorFromRoutes(stop.routes)
                                        let isBus = stop.attributes.vehicleType == 3
                                        
                                        HStack(spacing: 12) {
                                            // Icon circle
                                            Circle()
                                                .fill(Color(hex: color).opacity(0.15))
                                                .frame(width: 36, height: 36)
                                                .overlay(
                                                    Image(systemName: stop.attributes.icon)
                                                        .foregroundColor(Color(hex: color))
                                                        .font(.system(size: 14))
                                                )
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                // Stop name + distance
                                                HStack {
                                                    Text(stop.attributes.name)
                                                        .font(.subheadline)
                                                        .fontWeight(.medium)
                                                        .foregroundColor(.primary)
                                                        .lineLimit(1)
                                                    Spacer()
                                                    // Distance badge
                                                    if stop.distanceMiles > 0 {
                                                        Text(String(format: "%.1f mi", stop.distanceMiles))
                                                            .font(.caption2)
                                                            .foregroundColor(.secondary)
                                                    }
                                                }
                                                
                                                // Transit type label
                                                Text(stop.attributes.transitType)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                
                                                // Route badges
                                                if !stop.routes.isEmpty {
                                                    ScrollView(.horizontal, showsIndicators: false) {
                                                        HStack(spacing: 4) {
                                                            ForEach(stop.routes.prefix(4), id: \.id) { route in
                                                                HStack(spacing: 3) {
                                                                    // Show bus icon for bus routes
                                                                    if isBus {
                                                                        Image(systemName: "bus.fill")
                                                                            .font(.system(size: 8))
                                                                            .foregroundColor(.white)
                                                                    }
                                                                    Text(route.attributes.displayName)
                                                                        .font(.caption2)
                                                                        .fontWeight(.semibold)
                                                                        .foregroundColor(.white)
                                                                }
                                                                .padding(.horizontal, 6)
                                                                .padding(.vertical, 3)
                                                                .background(Color(hex: color))
                                                                .cornerRadius(4)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
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
                        Text("detail_posted_by".localized)
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
                        if let emailURL = URL(string: "mailto:\(listing.contactEmail)") {
                        Link(destination: emailURL) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                Text("detail_email_poster".localized)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(orangeColor)
                            .cornerRadius(14)
                        }
                        }

                        if !listing.contactPhone.isEmpty,
                           let telURL = URL(string: "tel:\(listing.contactPhone.filter { $0.isNumber || $0 == "+" })") {
                            Link(destination: telURL) {
                                HStack {
                                    Image(systemName: "phone.fill")
                                    Text("detail_call_poster".localized)
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
                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(orangeColor)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    if !alreadyReported { showReportAlert = true }
                } label: {
                    Image(systemName: alreadyReported ? "flag.fill" : "flag")
                        .foregroundColor(alreadyReported ? .orange : .secondary)
                }
                .disabled(alreadyReported)
            }
        }
        .navigationTitle(listing.title)
        .navigationBarTitleDisplayMode(.inline)
        .ignoresSafeArea(edges: .top)
        .alert("detail_report_title".localized, isPresented: $showReportAlert) {
            Button("detail_report_fake".localized, role: .destructive) {
                reportListing(reason: "Fake or Scam")
            }
            Button("detail_report_inappropriate".localized, role: .destructive) {
                reportListing(reason: "Inappropriate Content")
            }
            Button("detail_report_wrong".localized, role: .destructive) {
                reportListing(reason: "Wrong Information")
            }
            Button("common_cancel".localized, role: .cancel) {}
        } message: {
            Text("detail_report_message".localized)
        }
        .alert("detail_report_submitted".localized, isPresented: $reportSubmitted) {
            Button("common_ok".localized, role: .cancel) {}
        } message: {
            Text("detail_report_thanks".localized)
        }
        .task {
            await detailViewModel.fetchData(listing: listing)
            checkIfAlreadyReported()
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
        
        // Deterministic ID = listingId_uid — one document per user per listing.
        // setData on the same ID is a no-op if they somehow call twice.
        let reportDocId = "\(id)_\(uid)"
        db.collection("reports").document(reportDocId).setData(report) { error in
            if error == nil {
                db.collection("listings").document(id).updateData([
                    "reportCount": FieldValue.increment(Int64(1))
                ])
                reportSubmitted = true
                alreadyReported = true
            }
        }
    }

    func checkIfAlreadyReported() {
        guard let id = listing.id,
              let uid = Auth.auth().currentUser?.uid else { return }
        // Direct document read — no query, works with the updated security rule
        Firestore.firestore()
            .collection("reports")
            .document("\(id)_\(uid)")
            .getDocument { snapshot, _ in
                DispatchQueue.main.async {
                    alreadyReported = snapshot?.exists ?? false
                }
            }
    }

    // MARK: - Localized Safety Score
    // API always returns English — map to localized display string
    func localizedSafetyScore(_ score: String) -> String {
        switch score {
        case "Very Safe":       return "safety_very_safe".localized
        case "Generally Safe":  return "safety_generally_safe".localized
        case "Moderate":        return "safety_moderate".localized
        case "Use Caution":     return "safety_use_caution".localized
        case "High Activity":   return "safety_high_activity".localized
        default:                return score
        }
    }

    // MARK: - Safety Color
    func safetyColor(for score: String) -> Color {
        switch score {
        case "Very Safe":      return .green
        case "Generally Safe": return Color(hex: "00843D")
        case "Moderate":       return .orange
        case "Use Caution":    return .red
        case "High Activity":  return Color(hex: "8B0000")
        default:               return .secondary
        }
    }

    // MARK: - Safety Icon
    func safetyIcon(for score: String) -> String {
        switch score {
        case "Very Safe":      return "checkmark.shield.fill"
        case "Generally Safe": return "checkmark.shield.fill"
        case "Moderate":       return "exclamationmark.shield.fill"
        case "Use Caution":    return "xmark.shield.fill"
        case "High Activity":  return "xmark.shield.fill"
        default:               return "shield.slash.fill"
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
