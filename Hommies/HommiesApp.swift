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
    
    init() {
         FirebaseApp.configure()
     }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
