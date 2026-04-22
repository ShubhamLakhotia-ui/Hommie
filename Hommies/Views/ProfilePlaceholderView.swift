//
//  ProfilePlaceholderView.swift
//  Hommies
//
//  Created by Shubham Lakhotia on 4/21/26.
//
import SwiftUI
struct ProfilePlaceholderView: View {
    
    @EnvironmentObject var authViewModel: AuthViewModel
    let orangeColor = Color(hex: "E8622A")
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("🏠")
                .font(.system(size: 60))
            Text("Hommies")
                .font(.system(size: 28, weight: .bold, design: .rounded))
            
            Button {
                authViewModel.signOut()
            } label: {
                Text("Sign Out")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(orangeColor)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}
