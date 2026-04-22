import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var email: String
    var totalListings: Int
    var profileImageURL: String
    var createdAt: Date
    
    // Empty init for creating new users
    init(id: String? = nil, name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
        self.totalListings = 0
        self.profileImageURL = ""
        self.createdAt = Date()
    }
}

