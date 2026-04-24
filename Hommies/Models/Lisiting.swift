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
    var latitude: Double?
    var longitude: Double?
    var campusName: String?
    var reportCount: Int?
    // Room type options
    static let roomTypes = [
        "Private Room",
        "Shared Room",
        "Studio",
        "1 Bedroom",
        "2 Bedroom",
        "Entire Apartment"
    ]
    
    init(
        id: String? = nil,
        ownerId: String,
        ownerName: String,
        ownerEmail: String,
        title: String,
        description: String,
        price: Double,
        roomType: String,
        furnished: Bool,
        petsAllowed: Bool,
        utilitiesIncluded: Bool,
        availableFrom: Date,
        availableTo: Date,
        neighborhood: String,
        distanceToCampus: String,
        roommates: Int,
        imageURLs: [String],
        contactEmail: String,
        contactPhone: String,
        createdAt: Date,
        latitude: Double? = nil,
        longitude: Double? = nil,
        campusName: String? = nil,
        reportCount: Int? = nil,
    ) {
        self.id = id
        self.ownerId = ownerId
        self.ownerName = ownerName
        self.ownerEmail = ownerEmail
        self.title = title
        self.description = description
        self.price = price
        self.roomType = roomType
        self.furnished = furnished
        self.petsAllowed = petsAllowed
        self.utilitiesIncluded = utilitiesIncluded
        self.availableFrom = availableFrom
        self.availableTo = availableTo
        self.neighborhood = neighborhood
        self.distanceToCampus = distanceToCampus
        self.roommates = roommates
        self.imageURLs = imageURLs
        self.contactEmail = contactEmail
        self.contactPhone = contactPhone
        self.createdAt = createdAt
        self.latitude = latitude
        self.longitude = longitude
        self.campusName = campusName ?? nil
        self.reportCount = reportCount
    }
}

// MARK: - Mock Data for UI Testing
extension Listing {
    static let mockListings: [Listing] = [
        Listing(
            ownerId: "user1",
            ownerName: "John Smith",
            ownerEmail: "john@bu.edu",
            title: "Sunny private room near BU",
            description: "Beautiful room in a 3 bedroom apartment. Great natural light, close to T stop.",
            price: 950,
            roomType: "Private Room",
            furnished: true,
            petsAllowed: false,
            utilitiesIncluded: true,
            availableFrom: Date(),
            availableTo: Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date(),
            neighborhood: "Allston",
            distanceToCampus: "0.3 miles",
            roommates: 2,
            imageURLs: [],
            contactEmail: "john@bu.edu",
            contactPhone: "",
            createdAt: Date(),
            campusName: nil
        ),
        Listing(
            ownerId: "user2",
            ownerName: "Sarah Lee",
            ownerEmail: "sarah@neu.edu",
            title: "Cozy studio apartment",
            description: "Self contained studio, perfect for one person. Quiet street.",
            price: 1400,
            roomType: "Studio",
            furnished: true,
            petsAllowed: true,
            utilitiesIncluded: false,
            availableFrom: Date(),
            availableTo: Calendar.current.date(byAdding: .month, value: 4, to: Date()) ?? Date(),
            neighborhood: "Back Bay",
            distanceToCampus: "0.5 miles",
            roommates: 0,
            imageURLs: [],
            contactEmail: "sarah@neu.edu",
            contactPhone: "617-555-0101",
            createdAt: Date(),
            campusName: nil
        ),
        Listing(
            ownerId: "user3",
            ownerName: "Mike Chen",
            ownerEmail: "mike@mit.edu",
            title: "Shared room in student house",
            description: "Friendly student house, shared with 4 others. Great community vibe.",
            price: 650,
            roomType: "Shared Room",
            furnished: false,
            petsAllowed: false,
            utilitiesIncluded: true,
            availableFrom: Date(),
            availableTo: Calendar.current.date(byAdding: .month, value: 2, to: Date()) ?? Date(),
            neighborhood: "Cambridge",
            distanceToCampus: "1.2 miles",
            roommates: 4,
            imageURLs: [],
            contactEmail: "mike@mit.edu",
            contactPhone: "",
            createdAt: Date(),
            campusName: nil
        )
    ]
}
