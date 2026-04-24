//
//  AdminView.swift
//  Hommies
//
//  Created by Shubham Lakhotia on 4/24/26.
//
import SwiftUI
import FirebaseFirestore

struct AdminView: View {
    
    @State private var reportedListings: [Listing] = []
    @State private var isLoading = false
    @State private var showRestoreAlert = false
    @State private var showDeleteAlert = false
    @State private var selectedListing: Listing? = nil
    
    let orangeColor = Color(hex: "E8622A")
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                
                // MARK: - Header Stats
                HStack(spacing: 0) {
                    StatItem(value: "\(reportedListings.count)", label: "Reported")
                    Divider().frame(height: 40)
                    StatItem(
                        value: "\(reportedListings.filter { ($0.reportCount ?? 0) >= 3 }.count)",
                        label: "Hidden"
                    )
                    Divider().frame(height: 40)
                    StatItem(
                        value: "\(reportedListings.filter { ($0.reportCount ?? 0) < 3 }.count)",
                        label: "Flagged"
                    )
                }
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                .padding(.horizontal, 16)
                
                if isLoading {
                    ProgressView("Loading reported listings...")
                        .padding(40)
                        
                } else if reportedListings.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        Text("No reported listings")
                            .font(.headline)
                        Text("All listings are clean!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(40)
                    
                } else {
                    VStack(spacing: 12) {
                        ForEach(reportedListings) { listing in
                            VStack(alignment: .leading, spacing: 12) {
                                
                                // Status badge
                                HStack {
                                    // Hidden or flagged badge
                                    if (listing.reportCount ?? 0) >= 3 {
                                        Label("Hidden from browse", systemImage: "eye.slash.fill")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(Color.red)
                                            .cornerRadius(20)
                                    } else {
                                        Label("Flagged — still visible", systemImage: "flag.fill")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(Color.orange)
                                            .cornerRadius(20)
                                    }
                                    
                                    Spacer()
                                    
                                    // Report count
                                    Text("\(listing.reportCount ?? 0) reports")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.red)
                                }
                                
                                // Listing info
                                HStack(spacing: 12) {
                                    // Thumbnail
                                    if let firstURL = listing.imageURLs.first,
                                       let url = URL(string: firstURL) {
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 60, height: 60)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                            default:
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color(.systemGray5))
                                                    .frame(width: 60, height: 60)
                                            }
                                        }
                                    } else {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(.systemGray5))
                                            .frame(width: 60, height: 60)
                                            .overlay(
                                                Image(systemName: "photo")
                                                    .foregroundColor(.secondary)
                                            )
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(listing.title)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .lineLimit(1)
                                        Text("$\(Int(listing.price))/mo · \(listing.neighborhood)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("Posted by: \(listing.ownerEmail)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                                
                                // Action buttons
                                HStack(spacing: 8) {
                                    // Restore button
                                    Button {
                                        selectedListing = listing
                                        showRestoreAlert = true
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "checkmark.circle.fill")
                                            Text("Restore listing")
                                                .fontWeight(.medium)
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(Color.green)
                                        .cornerRadius(10)
                                    }
                                    
                                    // Delete button
                                    Button {
                                        selectedListing = listing
                                        showDeleteAlert = true
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "trash.fill")
                                            Text("Delete listing")
                                                .fontWeight(.medium)
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(Color.red)
                                        .cornerRadius(10)
                                    }
                                }
                            }
                            .padding(14)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        (listing.reportCount ?? 0) >= 3 ? Color.red.opacity(0.3) : Color.orange.opacity(0.3),
                                        lineWidth: 1
                                    )
                            )
                            .padding(.horizontal, 16)
                        }
                    }
                }
            }
            .padding(.vertical, 16)
        }
        .navigationTitle("Admin Panel")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    fetchReportedListings()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(orangeColor)
                }
            }
        }
        .onAppear {
            fetchReportedListings()
        }
        // Restore alert
        .alert("Restore Listing", isPresented: $showRestoreAlert) {
            Button("Restore", role: .none) {
                if let listing = selectedListing {
                    resetListing(listing)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will clear all reports on \"\(selectedListing?.title ?? "")\" and make it visible again.")
        }
        // Delete alert
        .alert("Delete Listing", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let listing = selectedListing {
                    deleteListing(listing)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Permanently delete \"\(selectedListing?.title ?? "")\"? This cannot be undone.")
        }
    }
    
    // Fetch ALL listings with at least 1 report
    func fetchReportedListings() {
        isLoading = true
        Task {
            do {
                let snapshot = try await Firestore.firestore()
                    .collection("listings")
                    .whereField("reportCount", isGreaterThan: 0)
                    .order(by: "reportCount", descending: true)
                    .getDocuments()
                
                await MainActor.run {
                    reportedListings = snapshot.documents.compactMap {
                        try? $0.data(as: Listing.self)
                    }
                    isLoading = false
                }
            } catch {
                print("Admin fetch error: \(error)")
                await MainActor.run { isLoading = false }
            }
        }
    }
    
    // Restore listing — clear all reports
    func resetListing(_ listing: Listing) {
        guard let id = listing.id else { return }
        Firestore.firestore()
            .collection("listings")
            .document(id)
            .updateData(["reportCount": 0]) { _ in
                fetchReportedListings()
            }
    }
    
    // Delete listing permanently
    func deleteListing(_ listing: Listing) {
        guard let id = listing.id else { return }
        Firestore.firestore()
            .collection("listings")
            .document(id)
            .delete { _ in
                fetchReportedListings()
            }
    }
}
