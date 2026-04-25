import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct PostListingView: View {
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var viewModel: ListingsViewModel
    @EnvironmentObject var localizationManager: LocalizationManager

    var existingListing: Listing? = nil
    var isEditing: Bool { existingListing != nil }

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
    @State private var availableTo = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var existingImageURLs: [String] = []
    @State private var newImages: [UIImage] = []
    @State private var localError = ""
    @State private var showSuccess = false
    @State private var latitude: Double = 0.0
    @State private var longitude: Double = 0.0
    @State private var locationName: String = ""
    @State private var showLocationPicker = false
    @State private var selectedCampus = Campus.northeastern
    @State private var isPosting = false
    
    let orangeColor = Color(hex: "E8622A")
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // MARK: - Photos
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "post_photos".localized, subtitle: "post_photos_subtitle".localized)
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
                                        let existingCount = existingImageURLs.count
                                        if index >= existingCount {
                                            let newIndex = index - existingCount
                                            if newIndex < selectedPhotoItems.count {
                                                selectedPhotoItems.remove(at: newIndex)
                                            }
                                        } else {
                                            existingImageURLs.remove(at: index)
                                        }
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
                                        Text("post_add_photo".localized)
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
                    
                    // Photo required hint
                    if selectedImages.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text("At least one photo is required")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding(.horizontal, 16)
                
                // MARK: - Basic Info
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "post_basic_info".localized, subtitle: nil)
                    HommiesTextField(icon: "pencil", placeholder: "post_listing_title".localized, text: $title)
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.secondarySystemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                        if description.isEmpty {
                            Text("post_description_placeholder".localized)
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
                    SectionHeader(title: "post_pricing".localized, subtitle: nil)
                    HommiesTextField(
                        icon: "dollarsign.circle.fill",
                        placeholder: "post_rent_placeholder".localized,
                        text: $price,
                        keyboardType: .numberPad
                    )
                }
                .padding(.horizontal, 16)
                
                // MARK: - Room Details
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "post_room_details".localized, subtitle: nil)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("post_room_type".localized)
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
                                    .onTapGesture { selectedRoomType = type }
                                }
                            }
                        }
                    }
                    HommiesTextField(
                        icon: "person.2.fill",
                        placeholder: "post_roommates_placeholder".localized,
                        text: $roommates,
                        keyboardType: .numberPad
                    )
                    VStack(spacing: 0) {
                        ToggleRow(icon: "sofa.fill", title: "post_furnished".localized, isOn: $furnished)
                        Divider().padding(.leading, 44)
                        ToggleRow(icon: "pawprint.fill", title: "post_pets_allowed".localized, isOn: $petsAllowed)
                        Divider().padding(.leading, 44)
                        ToggleRow(icon: "bolt.fill", title: "post_utilities_included".localized, isOn: $utilitiesIncluded)
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
                    SectionHeader(title: "post_nearest_campus".localized, subtitle: "post_nearest_campus_subtitle".localized)
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
                    if latitude != 0.0 && longitude != 0.0 {
                        HStack(spacing: 8) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(orangeColor)
                            Text("\("post_distance_to".localized) \(selectedCampus.name): \(distanceBetween(lat1: latitude, lon1: longitude, lat2: selectedCampus.coordinate.latitude, lon2: selectedCampus.coordinate.longitude))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 16)
                
                // MARK: - Location
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "post_location".localized, subtitle: nil)
                    HommiesTextField(icon: "location.fill", placeholder: "post_neighborhood_placeholder".localized, text: $neighborhood)
                    Button {
                        showLocationPicker = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: latitude == 0.0 ? "map" : "mappin.circle.fill")
                                .foregroundColor(orangeColor)
                                .frame(width: 20)
                            Text(locationName.isEmpty ? "post_pin_location".localized : locationName)
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
                    SectionHeader(title: "post_availability".localized, subtitle: nil)
                    VStack(spacing: 0) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(orangeColor)
                                .frame(width: 20)
                            DatePicker("post_available_from".localized,
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
                            DatePicker("post_available_to".localized,
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
                    SectionHeader(title: "post_contact".localized, subtitle: nil)
                    HStack(spacing: 12) {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(orangeColor)
                            .frame(width: 20)
                        Text(authViewModel.currentUser?.email ?? "")
                            .foregroundColor(.secondary)
                            .font(.body)
                        Spacer()
                        Text("post_auto_filled".localized)
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
                        placeholder: "post_phone_placeholder".localized,
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
                
                // MARK: - Post/Save Button
                Button {
                    handlePost()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(orangeColor)
                            .frame(height: 56)
                        if viewModel.isLoading || isPosting {
                            ProgressView().tint(.white)
                        } else {
                            Text(isEditing ? "edit_save_changes".localized : "post_button".localized)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .disabled(viewModel.isLoading || isPosting)
                
                Spacer().frame(height: 20)
            }
            .padding(.top, 16)
        }
        .navigationTitle(isEditing ? "edit_listing_title".localized : "post_title".localized)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            prefillIfEditing()
        }
        .alert(isEditing ? "edit_success_title".localized : "post_success_title".localized, isPresented: $showSuccess) {
            Button("OK") {
                if !isEditing {
                    resetForm()
                } else {
                    // Refresh listings to show updated photo
                    Task {
                        await viewModel.fetchListings()
                    }
                }
            }
        } message: {
            Text(isEditing ? "edit_success_message".localized : "post_success_message".localized)
        }
    }
    
    // MARK: - Pre-fill form if editing
    func prefillIfEditing() {
        guard let listing = existingListing else { return }
        title = listing.title
        description = listing.description
        price = "\(Int(listing.price))"
        selectedRoomType = listing.roomType
        roommates = "\(listing.roommates)"
        furnished = listing.furnished
        petsAllowed = listing.petsAllowed
        utilitiesIncluded = listing.utilitiesIncluded
        neighborhood = listing.neighborhood
        availableFrom = listing.availableFrom
        availableTo = listing.availableTo
        contactPhone = listing.contactPhone
        latitude = listing.latitude ?? 0.0
        longitude = listing.longitude ?? 0.0
        locationName = listing.neighborhood
        if let campusName = listing.campusName,
           let found = Campus.all.first(where: { $0.name == campusName }) {
            selectedCampus = found
        }
        // Store existing URLs separately
        existingImageURLs = listing.imageURLs
        // Load existing images for display
        Task {
            for urlString in listing.imageURLs {
                guard let url = URL(string: urlString) else { continue }
                if let (data, _) = try? await URLSession.shared.data(from: url),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        selectedImages.append(image)
                    }
                }
            }
        }
    }
    
    // MARK: - Handle Post / Update
    func handlePost() {
        // If editing — update existing listing
        if let existing = existingListing, let id = existing.id {
            Task { await updateListing(id: id) }
            return
        }
        
        // Validate at least 1 photo for new listing
        guard !selectedImages.isEmpty else {
            localError = "Please add at least one photo"
            return
        }
        guard Auth.auth().currentUser?.isEmailVerified == true else {
            localError = "error_email_not_verified".localized
            return
        }
        localError = ""
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            localError = "error_title_required".localized
            return
        }
        guard !description.trimmingCharacters(in: .whitespaces).isEmpty else {
            localError = "error_description_required".localized
            return
        }
        guard let priceDouble = Double(price), priceDouble >= 400 && priceDouble <= 10000 else {
            localError = "error_price_range".localized
            return
        }
        guard !neighborhood.trimmingCharacters(in: .whitespaces).isEmpty else {
            localError = "error_neighborhood_required".localized
            return
        }
        guard let user = authViewModel.currentUser,
              let uid = Auth.auth().currentUser?.uid else {
            localError = "error_sign_in_required".localized
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
            distanceToCampus: (latitude != 0.0 || longitude != 0.0)
                ? distanceBetween(
                    lat1: latitude, lon1: longitude,
                    lat2: selectedCampus.coordinate.latitude,
                    lon2: selectedCampus.coordinate.longitude)
                : "",
            roommates: Int(roommates) ?? 0,
            imageURLs: [],
            contactEmail: user.email,
            contactPhone: contactPhone,
            createdAt: Date(),
            latitude: latitude == 0.0 ? nil : latitude,
            longitude: longitude == 0.0 ? nil : longitude,
            campusName: selectedCampus.name
        )
        
        Task {
            await viewModel.postListing(listing: newListing, images: selectedImages)
            if viewModel.postSuccess {
                showSuccess = true
            }
        }
    }
    
    // MARK: - Update Listing in Firestore
    func updateListing(id: String) async {
        
        // Validate at least 1 photo when editing
        guard !selectedImages.isEmpty else {
            await MainActor.run {
                localError = "Please add at least one photo"
            }
            return
        }
        
        guard let priceDouble = Double(price),
              priceDouble >= 400 && priceDouble <= 10000 else {
            await MainActor.run {
                localError = "error_price_range".localized
            }
            return
        }
        
        await MainActor.run {
            isPosting = true
            localError = ""
        }
        
        // Start with remaining existing URLs
        var finalImageURLs = existingImageURLs
        
        // Upload only newly added images beyond existing count
        let newImagesToUpload = Array(selectedImages.dropFirst(existingImageURLs.count))
        
        for (index, image) in newImagesToUpload.enumerated() {
            if let imageData = image.jpegData(compressionQuality: 0.7) {
                do {
                    // Use user UID in path to match Storage rules
                    guard let uid = Auth.auth().currentUser?.uid else { continue }
                    let storageRef = Storage.storage()
                        .reference()
                        .child("listings/\(uid)/\(id)_photo_\(existingImageURLs.count + index).jpg")
                    let _ = try await storageRef.putDataAsync(imageData)
                    let url = try await storageRef.downloadURL()
                    finalImageURLs.append(url.absoluteString)
                    print("New photo uploaded successfully ✅")
                } catch {
                    print("Failed to upload image \(index): \(error)")
                }
            }
        }
        
        let updatedData: [String: Any] = [
            "title": title.trimmingCharacters(in: .whitespaces),
            "description": description.trimmingCharacters(in: .whitespaces),
            "price": priceDouble,
            "roomType": selectedRoomType,
            "furnished": furnished,
            "petsAllowed": petsAllowed,
            "utilitiesIncluded": utilitiesIncluded,
            "neighborhood": neighborhood.trimmingCharacters(in: .whitespaces),
            "distanceToCampus": (latitude != 0.0 || longitude != 0.0)
                ? distanceBetween(
                    lat1: latitude, lon1: longitude,
                    lat2: selectedCampus.coordinate.latitude,
                    lon2: selectedCampus.coordinate.longitude)
                : "",
            "campusName": selectedCampus.name,
            "roommates": Int(roommates) ?? 0,
            "availableFrom": Timestamp(date: availableFrom),
            "availableTo": Timestamp(date: availableTo),
            "contactPhone": contactPhone,
            "latitude": latitude == 0.0 ? nil : latitude,
            "longitude": longitude == 0.0 ? nil : longitude,
            "imageURLs": finalImageURLs
        ]
        
        do {
            try await Firestore.firestore()
                .collection("listings")
                .document(id)
                .updateData(updatedData)
            await MainActor.run {
                // Clear API cache so detail view shows fresh data
                APIService.shared.clearCache()
                isPosting = false
                showSuccess = true
            }
        } catch {
            await MainActor.run {
                localError = error.localizedDescription
                isPosting = false
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
        existingImageURLs = []
        newImages = []
        latitude = 0.0
        longitude = 0.0
        locationName = ""
        showLocationPicker = false
        selectedCampus = Campus.northeastern
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
