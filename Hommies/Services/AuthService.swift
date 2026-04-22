import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthService {
    
    static let shared = AuthService()
    private let db = Firestore.firestore()
    
    // MARK: - Sign Up
    func signUp(name: String, email: String, password: String) async throws -> User {
        // Create auth account
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let firebaseUser = result.user
        
        // Create user profile in Firestore
        let newUser = User(id: firebaseUser.uid, name: name, email: email)
        try db.collection("users").document(firebaseUser.uid).setData(from: newUser)
        
        return newUser
    }
    
    // MARK: - Sign In
    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }
    
    // MARK: - Sign Out
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    // MARK: - Current User
    var currentUser: FirebaseAuth.User? {
        return Auth.auth().currentUser
    }
    
    // MARK: - Fetch User Profile
    func fetchUserProfile(uid: String) async throws -> User {
        let document = try await db.collection("users").document(uid).getDocument()
        return try document.data(as: User.self)
    }
}
