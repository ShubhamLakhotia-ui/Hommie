import Foundation
import FirebaseAuth
import Combine


class AuthViewModel: ObservableObject {
    
    @Published var currentUser: User?
    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    
    private let authService = AuthService.shared
    
    init() {
        checkIfUserIsLoggedIn()
    }
    
    // MARK: - Check if already logged in
    func checkIfUserIsLoggedIn() {
        if let firebaseUser = authService.currentUser {
            self.isLoggedIn = true
            Task {
                await fetchCurrentUser(uid: firebaseUser.uid)
            }
        }
    }
    
    // MARK: - Sign Up
    func signUp(name: String, email: String, password: String) {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let user = try await authService.signUp(name: name, email: email, password: password)
                await MainActor.run {
                    self.currentUser = user
                    self.isLoggedIn = true
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Sign In
    func signIn(email: String, password: String) {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                try await authService.signIn(email: email, password: password)
                if let uid = authService.currentUser?.uid {
                    await fetchCurrentUser(uid: uid)
                }
                await MainActor.run {
                    self.isLoggedIn = true
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    let errorCode = (error as NSError).code
                    switch errorCode {
                    case 17004, 17026:
                        self.errorMessage = "Wrong email or password. Please try again."
                    case 17011:
                        self.errorMessage = "No account found with this email. Please sign up."
                    case 17010:
                        self.errorMessage = "Too many attempts. Please try again later."
                    default:
                        self.errorMessage = "Wrong email or password. Please try again."
                    }
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        do {
            try authService.signOut()
            self.currentUser = nil
            self.isLoggedIn = false
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Fetch Current User
    @MainActor
    func fetchCurrentUser(uid: String) async {
        do {
            self.currentUser = try await authService.fetchUserProfile(uid: uid)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    var isAdmin: Bool {
        return currentUser?.isAdmin == true
    }
}
