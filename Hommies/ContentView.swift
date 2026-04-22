//
//  ContentView.swift
//  Hommies
//
//  Created by Shubham Lakhotia on 4/20/26.
//

import SwiftUI

struct ContentView: View {
    
  
    @StateObject var authViewModel = AuthViewModel()
    
    var body: some View {
        // Watch isLoggedIn — whenever it changes, UI updates automatically
        if authViewModel.isLoggedIn {
            
            // User is logged in → show main app
            MainTabView()
                .environmentObject(authViewModel)
        } else {
            
            // User is not logged in → show welcome/auth screens
            WelcomeView()
                .environmentObject(authViewModel)
        }
    }
}
