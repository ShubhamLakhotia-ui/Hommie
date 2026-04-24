//
//  PostListingView.swift
//  Hommies
//
//  Created by Shubham Lakhotia on 4/22/26.
//

import SwiftUI
import PhotosUI
import FirebaseAuth

struct PostListingView: View {
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var viewModel: ListingsViewModel
    
    @State private var title = ""
    @State private var description = ""
    @State private var price = ""
    @State private var neighborhood = ""
    @State private var distanceToCampus = ""
    @State private var roommates = ""
    @State private var contactPhone = ""
    @State private var selectedRoomType = "Private Room"
    @State private var furnished = false
    @State private var petsAllowed = false
    @State private var utilitiesIncluded = false
    @State private var availableFrom = Date()
    // Default end date is 3 months from today — suits most student sublets
    @State private var availableTo = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var localError = ""
    @State private var showSuccess = false
    @State private var latitude: Double = 0.0
    @State private var longitude: Double = 0.0
    @State private var locationName: String = ""
    @State private var showLocationPicker = false
    @State private var selectedCampus = Campus.northeastern
    let orangeColor = Color(hex: "E8622A")
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // MARK: - Photos
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Photos", subtitle: "Add up to 5 photos")
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(0..<selectedImages.count, id: \.self) { index in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: selectedImages[index])
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    
                                    Button {
                                        selectedImages.remove(at: index)
                                        selectedPhotoItems.remove(at: index)
                                    } label: {
                                        ZStack {
                                            Circle()
                                                .fill(Color.black.opacity(0.6))
                                                .frame(width: 22, height: 22)
                                            Image(systemName: "xmark")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .offset(x: 6, y: -6)
                                }
                            }
                            
                            if selectedImages.count < 5 {
                                PhotosPicker(
                                    selection: $selectedPhotoItems,
                                    maxSelectionCount: 5 - selectedImages.count,
                                    matching: .images
                                ) {
                                    VStack(spacing: 8) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 24))
                                            .foregroundColor(orangeColor)
                                        Text("Add Photo")
                                            .font(.caption)
                                            .foregroundColor(orangeColor)
                                    }
                                    .frame(width: 100, height: 100)
                                    .background(orangeColor.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(orangeColor.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                                    )
                                }
                                .onChange(of: selectedPhotoItems) { _, newItems in
                                    Task {
                                        for item in newItems {
                                            if let data = try? await item.loadTransferable(type: Data.self),
                                               let image = UIImage(data: data) {
                                                if !selectedImages.contains(where: { $0.pngData() == image.pngData() }) {
                                                    selectedImages.append(image)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 2)
                        .padding(.vertical, 4)
                    }
                }
                .padding(.horizontal, 16)
                
                // MARK: - Basic Info
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Basic Info", subtitle: nil)
                    
                    HommiesTextField(icon: "pencil", placeholder: "Listing title", text: $title)
                    
                    // ZStack used to add placeholder text since TextEditor doesn't support it natively
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.secondarySystemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                        
                        if description.isEmpty {
                            Text("Describe your place — highlight what makes it special")
                                .foregroundColor(Color(.placeholderText))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .font(.body)
                        }
                        
                        TextEditor(text: $description)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .frame(minHeight: 100)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                    }
                    .frame(minHeight: 100)
                }
                .padding(.horizontal, 16)
                
                // MARK: - Pricing
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Pricing", subtitle: nil)
                    HommiesTextField(
                        icon: "dollarsign.circle.fill",
                        placeholder: "Monthly rent (e.g. 950)",
                        text: $price,
                        keyboardType: .numberPad
                    )
                }
                .padding(.horizontal, 16)
                
                // MARK: - Room Details
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Room Details", subtitle: nil)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Room type")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Listing.roomTypes, id: \.self) { type in
                                    FilterChip(
                                        title: type,
                                        isSelected: selectedRoomType == type,
                                        color: orangeColor
                                    )
                                    .onTapGesture {
                                        selectedRoomType = type
                                    }
                                }
                            }
                        }
                    }
                    
                    HommiesTextField(
                        icon: "person.2.fill",
                        placeholder: "Number of roommates (e.g. 2)",
                        text: $roommates,
                        keyboardType: .numberPad
                    )
                    
                    VStack(spacing: 0) {
                        ToggleRow(icon: "sofa.fill", title: "Furnished", isOn: $furnished)
                        Divider().padding(.leading, 44)
                        ToggleRow(icon: "pawprint.fill", title: "Pets allowed", isOn: $petsAllowed)
                        Divider().padding(.leading, 44)
                        ToggleRow(icon: "bolt.fill", title: "Utilities included", isOn: $utilitiesIncluded)
                    }
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 16)
                
                // MARK: - Campus Selection
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Nearest Campus", subtitle: "Distance will be calculated automatically")
                    
                    VStack(spacing: 0) {
                        ForEach(Campus.all, id: \.name) { campus in
                            Button {
                                selectedCampus = campus
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: selectedCampus.name == campus.name ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedCampus.name == campus.name ? orangeColor : .secondary)
                                        .font(.system(size: 20))
                                    Text(campus.name)
                                        .foregroundColor(.primary)
                                        .font(.body)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                            }
                            if campus.name != Campus.all.last?.name {
                                Divider().padding(.leading, 44)
                            }
                        }
                    }
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    
                    // Show calculated distance if location is pinned
                    if let lat = latitude == 0.0 ? nil : Optional(latitude),
                       let lon = longitude == 0.0 ? nil : Optional(longitude) {
                        HStack(spacing: 8) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(orangeColor)
                            Text("Distance to \(selectedCampus.name): \(distanceBetween(lat1: lat, lon1: lon, lat2: selectedCampus.coordinate.latitude, lon2: selectedCampus.coordinate.longitude))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 16)
                
                // MARK: - Location
                // MARK: - Location
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Location", subtitle: nil)
                    HommiesTextField(icon: "location.fill", placeholder: "Neighborhood (e.g. Allston)", text: $neighborhood)
                   
                    // Map pin button — opens LocationPickerView as sheet
                    Button {
                        showLocationPicker = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: latitude == 0.0 ? "map" : "mappin.circle.fill")
                                .foregroundColor(Color(hex: "E8622A"))
                                .frame(width: 20)
                            Text(locationName.isEmpty ? "Pin location on map" : locationName)
                                .foregroundColor(locationName.isEmpty ? .secondary : .primary)
                                .font(.body)
                                .lineLimit(1)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(latitude != 0.0 ? Color(hex: "E8622A").opacity(0.5) : Color(.systemGray4), lineWidth: 1)
                        )
                    }
            
                    
                }
                .padding(.horizontal, 16)
                .sheet(isPresented: $showLocationPicker) {
                    LocationPickerView(
                        latitude: $latitude,
                        longitude: $longitude,
                        locationName: $locationName
                    )
                }
               
                // MARK: - Availability
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Availability", subtitle: nil)
                    
                    VStack(spacing: 0) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(orangeColor)
                                .frame(width: 20)
                            DatePicker("Available from",
                                      selection: $availableFrom,
                                      displayedComponents: .date)
                            .accentColor(orangeColor)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        
                        Divider().padding(.leading, 44)
                        
                        HStack {
                            Image(systemName: "calendar.badge.checkmark")
                                .foregroundColor(orangeColor)
                                .frame(width: 20)
                            // in: availableFrom... prevents selecting end date before start date
                            DatePicker("Available to",
                                      selection: $availableTo,
                                      in: availableFrom...,
                                      displayedComponents: .date)
                            .accentColor(orangeColor)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 16)
                
                // MARK: - Contact
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Contact", subtitle: nil)
                    
                    // Email auto-filled from logged in user — not editable
                    HStack(spacing: 12) {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(orangeColor)
                            .frame(width: 20)
                        Text(authViewModel.currentUser?.email ?? "")
                            .foregroundColor(.secondary)
                            .font(.body)
                        Spacer()
                        Text("Auto-filled")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    
                    HommiesTextField(
                        icon: "phone.fill",
                        placeholder: "Phone number (optional)",
                        text: $contactPhone,
                        keyboardType: .phonePad
                    )
                }
                .padding(.horizontal, 16)
                
                // MARK: - Error
                if !localError.isEmpty {
                    Text(localError)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                        .multilineTextAlignment(.center)
                }
                
                // MARK: - Post Button
                Button {
                    handlePost()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(orangeColor)
                            .frame(height: 56)
                        if viewModel.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Post Listing")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .disabled(viewModel.isLoading)
                
                Spacer().frame(height: 20)
            }
            .padding(.top, 16)
        }
        .navigationTitle("Post a Listing")
        .navigationBarTitleDisplayMode(.large)
        .alert("Listing Posted!", isPresented: $showSuccess) {
            Button("OK") { resetForm() }
        } message: {
            Text("Your listing is now live for other students to see.")
        }
    }
    
    // MARK: - Handle Post
    func handlePost() {
        
        // Block posting if email not verified
        guard Auth.auth().currentUser?.isEmailVerified == true else {
            localError = "Please verify your email before posting. Check your inbox for a verification link."
            return
        }
        localError = ""
        
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            localError = "Please enter a title"
            return
        }
        guard !description.trimmingCharacters(in: .whitespaces).isEmpty else {
            localError = "Please enter a description"
            return
        }
        guard let priceDouble = Double(price), priceDouble >= 400 && priceDouble <= 10000 else {
            localError = "Price must be between $400 and $10,000/month"
            return
        }
        guard !neighborhood.trimmingCharacters(in: .whitespaces).isEmpty else {
            localError = "Please enter a neighborhood"
            return
        }
//        guard !distanceToCampus.trimmingCharacters(in: .whitespaces).isEmpty else {
//            localError = "Please enter distance to campus"
//            return
//        }
        guard let user = authViewModel.currentUser,
              let uid = Auth.auth().currentUser?.uid else {
            localError = "Please sign in to post a listing"
            return
        }
        
        let newListing = Listing(
            ownerId: uid,
            ownerName: user.name,
            ownerEmail: user.email,
            title: title.trimmingCharacters(in: .whitespaces),
            description: description.trimmingCharacters(in: .whitespaces),
            price: priceDouble,
            roomType: selectedRoomType,
            furnished: furnished,
            petsAllowed: petsAllowed,
            utilitiesIncluded: utilitiesIncluded,
            availableFrom: availableFrom,
            availableTo: availableTo,
            neighborhood: neighborhood.trimmingCharacters(in: .whitespaces),
            distanceToCampus: distanceBetween(
                lat1: latitude,
                lon1: longitude,
                lat2: selectedCampus.coordinate.latitude,
                lon2: selectedCampus.coordinate.longitude
            ),
            roommates: Int(roommates) ?? 0,
            imageURLs: [],
            contactEmail: user.email,
            contactPhone: contactPhone,
            createdAt: Date(),
            latitude: latitude == 0.0 ? nil : latitude,
            longitude: longitude == 0.0 ? nil : longitude,
            campusName: selectedCampus.name,
        )
        
        Task {
            await viewModel.postListing(listing: newListing, images: selectedImages)
            if viewModel.postSuccess {
                showSuccess = true
            }
        }
    }
    
    // MARK: - Reset Form
    func resetForm() {
        title = ""
        description = ""
        price = ""
        neighborhood = ""
        distanceToCampus = ""
        roommates = ""
        contactPhone = ""
        selectedRoomType = "Private Room"
        furnished = false
        petsAllowed = false
        utilitiesIncluded = false
        availableFrom = Date()
        availableTo = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
        selectedImages = []
        selectedPhotoItems = []
        latitude = 0.0
        longitude = 0.0
        locationName = ""
        showLocationPicker = false
    }
}

// MARK: - SectionHeader
struct SectionHeader: View {
    let title: String
    let subtitle: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - ToggleRow
struct ToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "E8622A"))
                .frame(width: 20)
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            Spacer()
            Toggle("", isOn: $isOn)
                .tint(Color(hex: "E8622A"))
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
