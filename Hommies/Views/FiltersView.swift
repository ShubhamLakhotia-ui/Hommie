import SwiftUI

struct FiltersView: View {
    
    @ObservedObject var viewModel: ListingsViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var localMinPrice: Double
    @State private var localMaxPrice: Double
    @State private var localFurnished: Bool?
    @State private var localPets: Bool?
    
    let orangeColor = Color(hex: "E8622A")
    
    init(viewModel: ListingsViewModel) {
        self.viewModel = viewModel
        _localMinPrice = State(initialValue: viewModel.minPrice)
        _localMaxPrice = State(initialValue: viewModel.maxPrice)
        _localFurnished = State(initialValue: viewModel.furnishedFilter)
        _localPets = State(initialValue: viewModel.petsFilter)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: - Price Range
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Price Range")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("$\(Int(localMinPrice)) - $\(Int(localMaxPrice))/mo")
                                .font(.subheadline)
                                .foregroundColor(orangeColor)
                                .fontWeight(.semibold)
                        }
                        
                        // Min price slider
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Minimum: $\(Int(localMinPrice))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Slider(value: $localMinPrice, in: 0...5000, step: 50)
                                .tint(orangeColor)
                                // Ensure min never exceeds max
                                .onChange(of: localMinPrice) { _, newValue in
                                    if newValue > localMaxPrice {
                                        localMinPrice = localMaxPrice
                                    }
                                }
                        }
                        
                        // Max price slider
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Maximum: $\(Int(localMaxPrice))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Slider(value: $localMaxPrice, in: 0...5000, step: 50)
                                .tint(orangeColor)
                                // Ensure max never goes below min
                                .onChange(of: localMaxPrice) { _, newValue in
                                    if newValue < localMinPrice {
                                        localMaxPrice = localMinPrice
                                    }
                                }
                        }
                    }
                    .padding(16)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    
                    // MARK: - Features
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Features")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.bottom, 12)
                        
                        VStack(spacing: 0) {
                            // Furnished filter
                            // nil = Any (no filter), true = furnished only, false = unfurnished only
                            HStack {
                                Image(systemName: "sofa.fill")
                                    .foregroundColor(orangeColor)
                                    .frame(width: 20)
                                Text("Furnished")
                                Spacer()
                                Picker("", selection: $localFurnished) {
                                    Text("Any").tag(Optional<Bool>.none)
                                    Text("Yes").tag(Optional<Bool>.some(true))
                                    Text("No").tag(Optional<Bool>.some(false))
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 140)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            
                            Divider().padding(.leading, 44)
                            
                            // Pets filter
                            HStack {
                                Image(systemName: "pawprint.fill")
                                    .foregroundColor(orangeColor)
                                    .frame(width: 20)
                                Text("Pets allowed")
                                Spacer()
                                Picker("", selection: $localPets) {
                                    Text("Any").tag(Optional<Bool>.none)
                                    Text("Yes").tag(Optional<Bool>.some(true))
                                    Text("No").tag(Optional<Bool>.some(false))
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 140)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                    }
                    
                    Spacer().frame(height: 20)
                }
                .padding(16)
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Reset — clears local state only, viewModel unchanged
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        localMinPrice = 0
                        localMaxPrice = 5000
                        localFurnished = nil
                        localPets = nil
                    }
                    .foregroundColor(.secondary)
                }
                
                // Apply — copies local state to viewModel then closes sheet
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        viewModel.minPrice = localMinPrice
                        viewModel.maxPrice = localMaxPrice
                        viewModel.furnishedFilter = localFurnished
                        viewModel.petsFilter = localPets
                        viewModel.applyFilters()
                        dismiss()
                    }
                    .foregroundColor(orangeColor)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
