import Foundation
import CoreLocation

// MARK: - MBTA Models
struct MBTAResponse: Codable {
    let data: [MBTAStop]
}

struct MBTAStop: Codable, Identifiable {
    let id: String
    let attributes: MBTAStopAttributes
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
    
    // MBTA Vehicle Types:
    // 0 = Light Rail (Green Line + Mattapan Trolley)
    // 1 = Heavy Rail (Red, Orange, Blue Lines)
    // 2 = Commuter Rail
    // 3 = Bus
    // 4 = Ferry
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
    
    var lineColor: String {
        switch vehicleType {
        case 0: return "00843D"
        case 1:
            let stopName = name.lowercased()
            if stopName.contains("red") { return "DA291C" }
            if stopName.contains("orange") { return "ED8B00" }
            if stopName.contains("blue") { return "003DA5" }
            return "80276C"
        case 2: return "80276C"
        case 3: return "FFC72C"
        case 4: return "008EAA"
        default: return "888780"
        }
    }
}

// MARK: - Crime Models
struct CrimeSQLResponse: Codable {
    let result: CrimeSQLResult
}

struct CrimeSQLResult: Codable {
    let records: [[String: AnyCodable]]
}

// AnyCodable lets us decode dynamic JSON values
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
    
    // In-memory cache — key is listing ID
    // Returns cached data instantly on second visit
    private var mbtaCache: [String: [MBTAStop]] = [:]
    private var crimeCache: [String: String] = [:]
    
    // MARK: - Fetch Nearby MBTA Stops (with cache)
    func fetchNearbyStops(listingID: String, latitude: Double, longitude: Double) async throws -> [MBTAStop] {
        
        if let cached = mbtaCache[listingID] {
            return cached
        }
        
        let urlString = "https://api-v3.mbta.com/stops?filter[latitude]=\(latitude)&filter[longitude]=\(longitude)&filter[radius]=0.5&sort=distance&page[limit]=8"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(MBTAResponse.self, from: data)
        mbtaCache[listingID] = response.data
        return response.data
    }
    
    // MARK: - Fetch Crime Data (with cache)
    // Uses COUNT(*) with year filter — accurate and fast
    // Only counts crimes from 2023 onwards — recent data is more relevant
    func fetchCrimeData(listingID: String, latitude: Double, longitude: Double) async throws -> String {
        
        if let cached = crimeCache[listingID] {
            return cached
        }
        
        let delta = 0.007
        let minLat = latitude - delta
        let maxLat = latitude + delta
        let minLon = longitude - delta
        let maxLon = longitude + delta
        
        // Dynamically calculate 2 years ago — works in any year
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
    // Thresholds based on 2 years of crime data within 1 mile radius
    private func safetyScore(from count: Int) -> String {
        // Calibrated against real Boston neighborhood data
        // 0.5 mile radius, last 2 years of crime incidents
        switch count {
        case 0...2000:    return "Very Safe"
        case 2000...4500: return "Generally Safe"
        case 4500...5500: return "Moderate"
        case 5501...8000: return "Use Caution"
        default:          return "High Activity"          }
    }
}
