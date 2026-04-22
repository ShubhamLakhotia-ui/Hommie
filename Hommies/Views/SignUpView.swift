import SwiftUI
import PhotosUI

struct SignUpView: View {
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = nil
    @State private var localError = ""
    
    let orangeColor = Color(hex: "E8622A")
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
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
                    
                    VStack(spacing: 8) {
                        Text("Create Account")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("Find your perfect student home")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        ZStack {
                            if let profileImage {
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(orangeColor, lineWidth: 3))
                            } else {
                                Circle()
                                    .fill(orangeColor.opacity(0.1))
                                    .frame(width: 100, height: 100)
                                    .overlay(Circle().stroke(orangeColor.opacity(0.3), lineWidth: 2))
                                VStack(spacing: 4) {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(orangeColor.opacity(0.5))
                                    Text("Optional")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Circle()
                                .fill(orangeColor)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white)
                                )
                                .offset(x: 35, y: 35)
                        }
                    }
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                profileImage = image
                            }
                        }
                    }
                    
                    VStack(spacing: 16) {
                        HommiesTextField(icon: "person.fill", placeholder: "Full Name", text: $name)
                        HommiesTextField(icon: "envelope.fill", placeholder: "Email Address", text: $email, keyboardType: .emailAddress)
                        HommiesSecureField(icon: "lock.fill", placeholder: "Password", text: $password, isVisible: $isPasswordVisible)
                        HommiesSecureField(icon: "lock.fill", placeholder: "Confirm Password", text: $confirmPassword, isVisible: $isConfirmPasswordVisible)
                    }
                    .padding(.horizontal, 24)
                    
                    if !localError.isEmpty || !authViewModel.errorMessage.isEmpty {
                        Text(localError.isEmpty ? authViewModel.errorMessage : localError)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 24)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button {
                        handleSignUp()
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(orangeColor)
                                .frame(height: 56)
                            if authViewModel.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Create Account")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .disabled(authViewModel.isLoading)
                    
                    HStack {
                        Text("Already have an account?")
                            .foregroundColor(.secondary)
                        Button("Sign In") {
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
    
    func handleSignUp() {
        localError = ""
        authViewModel.errorMessage = ""
        
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            localError = "Please enter your name"
            return
        }
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            localError = "Please enter your email"
            return
        }
        guard password.count >= 6 else {
            localError = "Password must be at least 6 characters"
            return
        }
        guard password == confirmPassword else {
            localError = "Passwords do not match"
            return
        }
        
        authViewModel.signUp(name: name, email: email, password: password)
    }
}

struct HommiesTextField: View {
    
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "E8622A"))
                .frame(width: 20)
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

struct HommiesSecureField: View {
    
    let icon: String
    let placeholder: String
    @Binding var text: String
    @Binding var isVisible: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "E8622A"))
                .frame(width: 20)
            if isVisible {
                TextField(placeholder, text: $text)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            } else {
                SecureField(placeholder, text: $text)
            }
            Button {
                isVisible.toggle()
            } label: {
                Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}
