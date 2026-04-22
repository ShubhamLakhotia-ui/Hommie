import SwiftUI
import FirebaseAuth
struct SignInView: View {
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var localError = ""
    
    let orangeColor = Color(hex: "E8622A")
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            // Subtle orange gradient at top
            VStack {
                LinearGradient(
                    colors: [Color(hex: "E8622A").opacity(0.15), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 300)
                Spacer()
            }
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: - Header
                    VStack(spacing: 8) {
                        Text("Welcome Back")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("Sign in to find your home")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Hommies logo — smaller version for sign in screen
                    ZStack {
                        Circle()
                            .fill(orangeColor.opacity(0.1))
                            .frame(width: 90, height: 90)
                        Text("🏠")
                            .font(.system(size: 44))
                    }
                    
                    // MARK: - Form Fields
                    VStack(spacing: 16) {
                        HommiesTextField(
                            icon: "envelope.fill",
                            placeholder: "Email Address",
                            text: $email,
                            keyboardType: .emailAddress
                        )
                        HommiesSecureField(
                            icon: "lock.fill",
                            placeholder: "Password",
                            text: $password,
                            isVisible: $isPasswordVisible
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    // MARK: - Error Message
                    if !localError.isEmpty || !authViewModel.errorMessage.isEmpty {
                        Text(localError.isEmpty ? authViewModel.errorMessage : localError)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 24)
                            .multilineTextAlignment(.center)
                    }
                    
                    // MARK: - Sign In Button
                    Button {
                        handleSignIn()
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(orangeColor)
                                .frame(height: 56)
                            if authViewModel.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Sign In")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .disabled(authViewModel.isLoading)
                    // Add this below the password field in SignInView
                    Button("Forgot Password?") {
                        forgotPassword()
                    }
                    .font(.caption)
                    .foregroundColor(orangeColor)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 24)
                    // MARK: - Sign Up Link
                    HStack {
                        Text("Don't have an account?")
                            .foregroundColor(.secondary)
                        // dismiss goes back to WelcomeView
                        // user can then tap Get Started
                        Button("Sign Up") {
                            dismiss()
                        }
                        .foregroundColor(orangeColor)
                        .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    
                    Spacer().frame(height: 20)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(orangeColor)
                }
            }
        }
    }
    
    func handleSignIn() {
        localError = ""
        authViewModel.errorMessage = ""
        
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            localError = "Please enter your email"
            return
        }
        guard !password.isEmpty else {
            localError = "Please enter your password"
            return
        }
        
        authViewModel.signIn(email: email, password: password)
    }
    func forgotPassword() {
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            localError = "Enter your email first then tap Forgot Password"
            return
        }
        // Firebase sends a reset email — works even if account doesn't exist
        // Firebase won't tell you if email exists or not (security)
        Auth.auth().sendPasswordReset(withEmail: email) { _ in
            localError = "If this email exists, a reset link has been sent."
        }
    }
}
