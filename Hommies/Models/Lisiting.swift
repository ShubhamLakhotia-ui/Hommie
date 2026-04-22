import Foundation
import FirebaseFirestore

struct Listing: Identifiable, Codable {
    @DocumentID var id: String?
    var ownerId: String
    var ownerName: String
    var ownerEmail: String
    var title: String
    var description: String
    var price: Double
    var roomType: String
    var furnished: Bool
    var petsAllowed: Bool
    var utilitiesIncluded: Bool
    var availableFrom: Date
    var availableTo: Date
    var neighborhood: String
    var distanceToCampus: String
    var roommates: Int
    var imageURLs: [String]
    var contactEmail: String
    var contactPhone: String
    var createdAt: Date
    
    // Room type options
    static let roomTypes = [
        "Private Room",
        "Shared Room",
        "Studio",
        "1 Bedroom",
        "2 Bedroom",
        "Entire Apartment"
    ]
}

