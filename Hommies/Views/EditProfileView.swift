//
//  EditProfileView.swift
//  Hommies
//
//  Created by Shubham Lakhotia on 4/25/26.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import PhotosUI

struct EditProfileView: View {
    
    @ObservedObject var authViewModel: AuthViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = nil
    
    let orangeColor = Color(hex: "E8622A")
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: - Profile Photo
                    VStack(spacing: 12) {
                        ZStack(alignment: .bottomTrailing) {
                            if let image = profileImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 90, height: 90)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(orangeColor.opacity(0.15))
                                    .frame(width: 90, height: 90)
                                    .overlay(
                                        Text(String(name.prefix(1).uppercased()))
                                            .font(.system(size: 36, weight: .bold))
                                            .foregroundColor(orangeColor)
                                    )
                            }
                            
                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                Circle()
                                    .fill(orangeColor)
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .foregroundColor(.white)
                                            .font(.system(size: 12))
                                    )
                            }
                            .onChange(of: selectedPhoto) { _, newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                                       let image = UIImage(data: data) {
                                        profileImage = image
                                    }
                                }
                            }
                        }
                        
                        Text("edit_profile_tap_camera".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // MARK: - Name Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("field_full_name".localized)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 24)

                        HommiesTextField(
                            icon: "person.fill",
                            placeholder: "edit_profile_name_placeholder".localized,
                            text: $name
                        )
                        .padding(.horizontal, 24)
                    }
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 24)
                    }
                    
                    // MARK: - Save Button
                    Button {
                        saveProfile()
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("edit_save_changes".localized)
                                    .fontWeight(.semibold)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(name.isEmpty ? Color.gray : orangeColor)
                        .cornerRadius(14)
                    }
                    .padding(.horizontal, 24)
                    .disabled(isLoading || name.isEmpty)
                }
            }
            .navigationTitle("edit_profile_title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("edit_profile_cancel".localized) { dismiss() }
                        .foregroundColor(.secondary)
                }
            }
            .onAppear {
                name = authViewModel.currentUser?.name ?? ""   // Load existing profile image if available
                if let imageURLString = authViewModel.currentUser?.profileImageURL,
                   !imageURLString.isEmpty,
                   let url = URL(string: imageURLString) {
                    Task {
                        if let (data, _) = try? await URLSession.shared.data(from: url),
                           let image = UIImage(data: data) {
                            await MainActor.run {
                                profileImage = image
                            }
                        }
                    }
                }
            }
            .alert("edit_profile_success_title".localized, isPresented: $showSuccess) {
                Button("common_ok".localized) { dismiss() }
            } message: {
                Text("edit_profile_success_message".localized)
            }
        }
    }
    
    func saveProfile() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "edit_profile_name_empty".localized
            return
        }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                var updateData: [String: Any] = [
                    "name": name.trimmingCharacters(in: .whitespaces)
                ]
                
                // Upload photo if user selected a NEW one
                if let image = profileImage,
                   let imageData = image.jpegData(compressionQuality: 0.7) {
                    
                    // Create fresh storage reference each time
                    let storageRef = Storage.storage()
                        .reference()
                        .child("profile_images/\(uid).jpg")
                    
                    // Delete old photo first to avoid conflicts
                    try? await storageRef.delete()
                    
                    // Upload new photo
                    let metadata = StorageMetadata()
                    metadata.contentType = "image/jpeg"
                    
                    let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
                    let downloadURL = try await storageRef.downloadURL()
                    updateData["profileImageURL"] = downloadURL.absoluteString
                }
                
                // Update Firestore
                try await Firestore.firestore()
                    .collection("users")
                    .document(uid)
                    .updateData(updateData)
                
                await MainActor.run {
                    authViewModel.currentUser?.name = name.trimmingCharacters(in: .whitespaces)
                    isLoading = false
                    showSuccess = true
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}
