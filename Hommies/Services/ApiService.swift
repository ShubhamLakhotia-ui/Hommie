import Foundation
import CoreLocation

// MARK: - MBTA Models
struct MBTAResponse: Codable {
    let data: [MBTAStop]
}

struct MBTARoutesResponse: Codable {
    let data: [MBTARoute]
}

struct MBTARoute: Codable {
    let id: String
    let attributes: MBTARouteAttributes
}

struct MBTARouteAttributes: Codable {
    let longName: String
    let shortName: String
    let type: Int
    
    enum CodingKeys: String, CodingKey {
        case longName = "long_name"
        case shortName = "short_name"
        case type
    }
    
    // Use short name for buses (e.g. "28"), long name for subway (e.g. "Red Line")
    var displayName: String {
        return shortName.isEmpty ? longName : shortName
    }
}

struct MBTAStop: Codable, Identifiable {
    let id: String
    let attributes: MBTAStopAttributes
    var routes: [MBTARoute] = []
    // Calculated after fetch — not from API response
    var distanceMiles: Double = 0.0
    
    enum CodingKeys: String, CodingKey {
        case id
        case attributes
    }
}

struct MBTAStopAttributes: Codable {
    let name: String
    let vehicleType: Int?
    let latitude: Double?
    let longitude: Double?
    let description: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case vehicleType = "vehicle_type"
        case latitude
        case longitude
        case description
    }
    
    // 0 = Light Rail, 1 = Heavy Rail, 2 = Commuter Rail, 3 = Bus, 4 = Ferry
    var transitType: String {
        switch vehicleType {
        case 0: return "Green Line"
        case 1:
            let stopName = name.lowercased()
            if stopName.contains("red") || description?.lowercased().contains("red") == true {
                return "Red Line"
            } else if stopName.contains("orange") || description?.lowercased().contains("orange") == true {
                return "Orange Line"
            } else if stopName.contains("blue") || description?.lowercased().contains("blue") == true {
                return "Blue Line"
            }
            return "Subway"
        case 2: return "Commuter Rail"
        case 3: return "Bus"
        case 4: return "Ferry"
        default: return "Transit"
        }
    }
    
    var icon: String {
        switch vehicleType {
        case 0, 1: return "tram.fill"
        case 2: return "train.side.front.car"
        case 3: return "bus.fill"
        case 4: return "ferry.fill"
        default: return "mappin.circle.fill"
        }
    }
    
    // Fallback color based on vehicle type
    var lineColor: String {
        switch vehicleType {
        case 0: return "00843D"
        case 1: return "ED8B00"
        case 2: return "80276C"
        case 3: return "FFC72C"
        case 4: return "008EAA"
        default: return "888780"
        }
    }
    
    // Accurate color from actual route name — more reliable than vehicleType alone
    func lineColorFromRoutes(_ routes: [MBTARoute]) -> String {
        guard let firstRoute = routes.first else { return lineColor }
        let name = firstRoute.attributes.longName.lowercased()
        if name.contains("red") { return "DA291C" }
        if name.contains("orange") { return "ED8B00" }
        if name.contains("blue") { return "003DA5" }
        if name.contains("green") { return "00843D" }
        if name.contains("silver") { return "7C878E" }
        if name.contains("fairmount") { return "80276C" }
        if name.contains("franklin") { return "80276C" }
        return lineColor
    }
}

// MARK: - Crime Models
struct CrimeSQLResponse: Codable {
    let result: CrimeSQLResult
}

struct CrimeSQLResult: Codable {
    let records: [[String: AnyCodable]]
}

struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let int = try? container.decode(Int.self) {
            value = int
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else {
            value = ""
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let string = value as? String {
            try container.encode(string)
        } else if let int = value as? Int {
            try container.encode(int)
        }
    }
}

// MARK: - API Service
class APIService {
    
    static let shared = APIService()
    private var mbtaCache: [String: [MBTAStop]] = [:]
    private var crimeCache: [String: String] = [:]
    
    // MARK: - Fetch Nearby MBTA Stops (with cache)
    // Fetches subway, commuter rail and bus separately with different radii
    func fetchNearbyStops(listingID: String, latitude: Double, longitude: Double) async throws -> [MBTAStop] {
        
        if let cached = mbtaCache[listingID] {
            return cached
        }
        
        // Fetch all three types concurrently
        async let subwayFetch = fetchStopsByType(
            latitude: latitude, longitude: longitude,
            radius: 1.0,
            routeType: "0,1"
        )
        async let busFetch = fetchStopsByType(
            latitude: latitude, longitude: longitude,
            radius: 0.3,
            routeType: "3"
        )
        async let commuterFetch = fetchStopsByType(
            latitude: latitude, longitude: longitude,
            radius: 1.5,
            routeType: "2"
        )
        
        let (subway, bus, commuter) = try await (subwayFetch, busFetch, commuterFetch)
        
        // Subway first then commuter rail then bus
        var allStops = subway + commuter + bus
        
        // Remove duplicates by name — same station can have different IDs per platform
        var seenNames = Set<String>()
        allStops = allStops.filter { seenNames.insert($0.attributes.name).inserted }
        
        let limited = Array(allStops.prefix(8))
        
        // Fetch routes for each stop
        var stopsWithRoutes: [MBTAStop] = []
        for var stop in limited {
            if let routes = try? await fetchRoutes(for: stop.id) {
                stop.routes = routes
            }
            stopsWithRoutes.append(stop)
        }
        
        mbtaCache[listingID] = stopsWithRoutes
        return stopsWithRoutes
    }
    
    // Fetch stops filtered by vehicle type and radius
    private func fetchStopsByType(
        latitude: Double,
        longitude: Double,
        radius: Double,
        routeType: String
    ) async throws -> [MBTAStop] {
        let urlString = "https://api-v3.mbta.com/stops?filter[latitude]=\(latitude)&filter[longitude]=\(longitude)&filter[radius]=\(radius)&filter[route_type]=\(routeType)&sort=distance&page[limit]=4"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let listingLocation = CLLocation(latitude: latitude, longitude: longitude)
        var response = try JSONDecoder().decode(MBTAResponse.self, from: data)
        var stopsWithDistance = response.data
        
        // Calculate distance from listing to each stop in miles
        for i in 0..<stopsWithDistance.count {
            if let stopLat = stopsWithDistance[i].attributes.latitude,
               let stopLon = stopsWithDistance[i].attributes.longitude {
                let stopLocation = CLLocation(latitude: stopLat, longitude: stopLon)
                let distanceMeters = listingLocation.distance(from: stopLocation)
                stopsWithDistance[i].distanceMiles = distanceMeters / 1609.344
            }
        }
        return stopsWithDistance
    }
    
    // Fetch all routes serving a specific stop
    private func fetchRoutes(for stopID: String) async throws -> [MBTARoute] {
        let urlString = "https://api-v3.mbta.com/routes?filter[stop]=\(stopID)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(MBTARoutesResponse.self, from: data)
        return response.data
    }
    
    // MARK: - Fetch Crime Data (with cache)
    func fetchCrimeData(listingID: String, latitude: Double, longitude: Double) async throws -> String {
        
        if let cached = crimeCache[listingID] {
            return cached
        }
        
        let delta = 0.007
        let minLat = latitude - delta
        let maxLat = latitude + delta
        let minLon = longitude - delta
        let maxLon = longitude + delta
        
        // Dynamically calculate 2 years ago
        let currentYear = Calendar.current.component(.year, from: Date())
        let twoYearsAgo = currentYear - 2
        
        let sql = "SELECT COUNT(*) as total FROM \"b973d8cb-eeb2-4e7e-99da-c92938efc9c0\" WHERE CAST(\"Lat\" as FLOAT) > \(minLat) AND CAST(\"Lat\" as FLOAT) < \(maxLat) AND CAST(\"Long\" as FLOAT) > \(minLon) AND CAST(\"Long\" as FLOAT) < \(maxLon) AND CAST(\"YEAR\" as INT) >= \(twoYearsAgo)"
        
        let urlString = "https://data.boston.gov/api/3/action/datastore_search_sql?sql=\(sql)"
        
        guard let encodedURL = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedURL) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        if let rawString = String(data: data, encoding: .utf8) {
            print("Crime API Response: \(rawString)")
        }
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let result = json["result"] as? [String: Any],
           let records = result["records"] as? [[String: Any]],
           let first = records.first,
           let count = first["total"] as? Int {
            let score = safetyScore(from: count)
            crimeCache[listingID] = score
            print("Crime count: \(count) → \(score)")
            return score
        }
        
        return "Data unavailable"
    }
    
    // MARK: - Clear Cache
    func clearCache() {
        mbtaCache.removeAll()
        crimeCache.removeAll()
    }
    
    // MARK: - Safety Score
    private func safetyScore(from count: Int) -> String {
        switch count {
        case 0...2000:    return "Very Safe"
        case 2001...4500: return "Generally Safe"
        case 4501...5500: return "Moderate"
        case 5501...8000: return "Use Caution"
        default:          return "High Activity"
        }
    }
}
