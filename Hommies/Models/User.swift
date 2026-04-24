import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var email: String
    var totalListings: Int
    var profileImageURL: String
    var createdAt: Date
    var isAdmin: Bool?
    
    
    // Empty init for creating new users
    init(id: String? = nil, name: String, email: String,isAdmin: Bool? = nil,) {
        self.id = id
        self.name = name
        self.email = email
        self.totalListings = 0
        self.profileImageURL = ""
        self.createdAt = Date()
        self.isAdmin = isAdmin
    }
}

