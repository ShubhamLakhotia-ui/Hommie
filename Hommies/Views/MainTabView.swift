//
//  MainTabView.swift
//  Hommies
//
//  Created by Shubham Lakhotia on 4/21/26.
//

import SwiftUI

struct MainTabView: View {
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    
    // ONE shared ViewModel created here — injected into all tabs
    @StateObject private var listingsViewModel = ListingsViewModel()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            ListingsView()
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                        Text("Home")
                    }
                }
                .tag(0)
            
            Text("Search")
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 1 ? "magnifyingglass.circle.fill" : "magnifyingglass")
                        Text("Search")
                    }
                }
                .tag(1)
            
            PostListingView()
                .tabItem {
                    VStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Post")
                    }
                }
                .tag(2)
            
            FavoritesView()
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 3 ? "heart.fill" : "heart")
                        Text("Saved")
                    }
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 4 ? "person.fill" : "person")
                        Text("Profile")
                    }
                }
                .tag(4)
        }
        .accentColor(Color(hex: "E8622A"))
        // Inject ONE shared listingsViewModel into entire tab bar environment
        // Now ALL tabs can access it via @EnvironmentObject
        .environmentObject(listingsViewModel)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color(hex: "E8622A"))
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(Color(hex: "E8622A")),
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
            ]
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor.systemGray,
                .font: UIFont.systemFont(ofSize: 10, weight: .regular)
            ]
            appearance.shadowColor = UIColor.systemGray5
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
