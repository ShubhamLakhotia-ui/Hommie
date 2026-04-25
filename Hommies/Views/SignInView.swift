import SwiftUI
import FirebaseAuth
struct SignInView: View {
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
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
                        Text("auth_welcome_back".localized)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("auth_sign_in_subtitle".localized)
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
                            placeholder: "field_email".localized,
                            text: $email,
                            keyboardType: .emailAddress
                        )
                        HommiesSecureField(
                            icon: "lock.fill",
                            placeholder: "field_password".localized,
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
                                Text("auth_sign_in".localized)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .disabled(authViewModel.isLoading)
                    // Add this below the password field in SignInView
                    Button("auth_forgot_password".localized) {
                        forgotPassword()
                    }
                    .font(.caption)
                    .foregroundColor(orangeColor)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 24)
                    // MARK: - Sign Up Link
                    HStack {
                        Text("auth_no_account".localized)
                            .foregroundColor(.secondary)
                        Button("auth_sign_up".localized) {
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
                        Text("auth_back".localized)
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
            localError = "error_email_required".localized
            return
        }
        guard !password.isEmpty else {
            localError = "error_password_required".localized
            return
        }
        
        authViewModel.signIn(email: email, password: password)
    }
    func forgotPassword() {
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            localError = "error_enter_email_first".localized
            return
        }
        Auth.auth().sendPasswordReset(withEmail: email) { _ in
            localError = "error_reset_sent".localized
        }
    }
}
