import SwiftUI
import MapKit

// Helper struct — MapAnnotation needs Identifiable items
struct PinLocation: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
}

struct LocationPickerView: View {
    
    @Environment(\.dismiss) var dismiss
    @Binding var latitude: Double
    @Binding var longitude: Double
    @Binding var locationName: String
    
    // Store region directly — avoids switch/case pattern matching issues
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 42.3601, longitude: -71.0589),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @State private var pinCoordinate = CLLocationCoordinate2D(latitude: 42.3601, longitude: -71.0589)
    @State private var pinLocation: [PinLocation] = []
    @State private var resolvedAddress = ""
    @State private var isGeocoding = false
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @State private var showSuggestions = false
    
    let orangeColor = Color(hex: "E8622A")
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                
                // MARK: - Map
                // coordinateRegion binding gives direct access to region
                // No switch/case needed — region is a plain @State var
                Map(coordinateRegion: $region, annotationItems: pinLocation) { pin in
                    MapAnnotation(coordinate: pin.coordinate) {
                        ZStack {
                            Circle()
                                .fill(orangeColor)
                                .frame(width: 32, height: 32)
                            Image(systemName: "house.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 14))
                        }
                    }
                }
                .onTapGesture { location in
                    showSuggestions = false
                    searchText = ""
                    
                    // Convert screen tap position to map coordinates
                    // region is directly accessible — no pattern matching needed
                    let screenWidth = UIScreen.main.bounds.width
                    let screenHeight = UIScreen.main.bounds.height
                    let tapX = location.x / screenWidth
                    let tapY = location.y / screenHeight
                    let newLat = region.center.latitude + (0.5 - tapY) * region.span.latitudeDelta
                    let newLon = region.center.longitude + (tapX - 0.5) * region.span.longitudeDelta
                    pinCoordinate = CLLocationCoordinate2D(latitude: newLat, longitude: newLon)
                    pinLocation = [PinLocation(coordinate: pinCoordinate)]
                    reverseGeocode(coordinate: pinCoordinate)
                }
                .ignoresSafeArea(edges: .bottom)
                
                // MARK: - Search Bar + Suggestions
                VStack(spacing: 0) {
                    
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search address...", text: $searchText)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: searchText) { _, newValue in
                                if newValue.isEmpty {
                                    searchResults = []
                                    showSuggestions = false
                                } else {
                                    searchAddress(query: newValue)
                                }
                            }
                        
                        if isSearching {
                            ProgressView().scaleEffect(0.7)
                        } else if !searchText.isEmpty {
                            Button {
                                searchText = ""
                                searchResults = []
                                showSuggestions = false
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    
                    // MARK: - Search Suggestions
                    if showSuggestions && !searchResults.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(searchResults.prefix(5), id: \.self) { item in
                                Button {
                                    selectSearchResult(item)
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "mappin.circle.fill")
                                            .foregroundColor(orangeColor)
                                            .font(.system(size: 16))
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.name ?? "Unknown")
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                                .lineLimit(1)
                                            Text(item.placemark.title ?? "")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                }
                                if item != searchResults.prefix(5).last {
                                    Divider().padding(.leading, 44)
                                }
                            }
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal, 12)
                        .padding(.top, 4)
                    }
                    
                    Spacer()
                    
                    // MARK: - Address Card
                    VStack(spacing: 8) {
                        if isGeocoding {
                            ProgressView().tint(orangeColor)
                        } else {
                            HStack(spacing: 8) {
                                Image(systemName: "location.fill")
                                    .foregroundColor(orangeColor)
                                Text(resolvedAddress.isEmpty ? "Search or tap map to set location" : resolvedAddress)
                                    .font(.subheadline)
                                    .foregroundColor(resolvedAddress.isEmpty ? .secondary : .primary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .padding(16)
                }
            }
            .navigationTitle("Pin Your Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Confirm") {
                        latitude = pinCoordinate.latitude
                        longitude = pinCoordinate.longitude
                        locationName = resolvedAddress
                        dismiss()
                    }
                    .foregroundColor(orangeColor)
                    .fontWeight(.semibold)
                    .disabled(resolvedAddress.isEmpty)
                }
            }
            .onAppear {
                reverseGeocode(coordinate: pinCoordinate)
            }
        }
    }
    
    // MARK: - Search Address
    // MKLocalSearch queries Apple Maps — free, no API key needed
    func searchAddress(query: String) {
        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        // Bias results towards Boston area
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 42.3601, longitude: -71.0589),
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            isSearching = false
            if let response = response {
                searchResults = response.mapItems
                showSuggestions = !response.mapItems.isEmpty
            }
        }
    }
    
    // MARK: - Select Search Result
    // Moves map and pin to selected address
    func selectSearchResult(_ item: MKMapItem) {
        let coordinate = item.placemark.coordinate
        pinCoordinate = coordinate
        pinLocation = [PinLocation(coordinate: coordinate)]
        withAnimation {
            region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
        resolvedAddress = item.placemark.title ?? item.name ?? ""
        searchText = item.name ?? ""
        showSuggestions = false
        searchResults = []
    }
    
    // MARK: - Reverse Geocode
    // Converts lat/long to human readable address string
    func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        isGeocoding = true
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            isGeocoding = false
            if let placemark = placemarks?.first {
                var components: [String] = []
                if let street = placemark.thoroughfare { components.append(street) }
                if let neighborhood = placemark.subLocality { components.append(neighborhood) }
                if let city = placemark.locality { components.append(city) }
                resolvedAddress = components.joined(separator: ", ")
            }
        }
    }
}
