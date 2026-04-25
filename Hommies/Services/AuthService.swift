import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class AuthService {
    
    static let shared = AuthService()
    private let db = Firestore.firestore()
    
    // MARK: - Sign Up
    func signUp(name: String, email: String, password: String, profileImageData: Data? = nil) async throws -> User {
        
        // Step 1 — Create Firebase Auth account
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let firebaseUser = result.user
        
        // Step 2 — Send email verification
        try await result.user.sendEmailVerification()
        
        var profileImageURL = ""
        
        // Step 3 — Upload profile photo if provided
        // Wrapped in do/catch so photo failure never blocks account creation
        // User can always update photo later from Edit Profile
        if let imageData = profileImageData {
            do {
                let storageRef = Storage.storage()
                    .reference()
                    .child("profile_images/\(firebaseUser.uid).jpg")
                
                let metadata = StorageMetadata()
                metadata.contentType = "image/jpeg"
                
                // Upload image data
                let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
                
                // Get download URL to save in Firestore
                let url = try await storageRef.downloadURL()
                profileImageURL = url.absoluteString
                print("Profile photo uploaded successfully ✅")
                
            } catch {
                // Photo upload failed but account creation continues
                // User can update photo later from Edit Profile
                print("Profile photo upload failed — continuing without photo: \(error)")
            }
        }
        
        // Step 4 — ALWAYS save user profile to Firestore
        // This runs whether or not photo upload succeeded
        var newUser = User(id: firebaseUser.uid, name: name, email: email)
        newUser.profileImageURL = profileImageURL
        newUser.isAdmin = false
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
