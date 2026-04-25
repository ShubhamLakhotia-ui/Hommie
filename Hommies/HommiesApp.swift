//
//  HommiesApp.swift
//  Hommies
//
//  Created by Shubham Lakhotia on 4/20/26.
//

import SwiftUI
import FirebaseCore
@main
struct HommiesApp: App {
    @StateObject private var localizationManager = LocalizationManager.shared
    init() {
        FirebaseApp.configure()
        // Increase URLCache so listing photos survive tab switches and account
        // changes without needing a network round-trip to reload.
        URLCache.shared = URLCache(
            memoryCapacity: 50 * 1024 * 1024,   // 50 MB in-memory
            diskCapacity:  200 * 1024 * 1024,   // 200 MB on-disk
            diskPath: "hommies_image_cache"
        )
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AuthViewModel())
                .environmentObject(localizationManager)
        }
    }
}
