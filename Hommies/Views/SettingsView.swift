//
//  SettingsView.swift
//  Hommies
//
//  Created by Shubham Lakhotia on 4/24/26.
//
import SwiftUI

struct SettingsView: View {
    
    @ObservedObject var localization = LocalizationManager.shared
    let orangeColor = Color(hex: "E8622A")
    
    var body: some View {
        NavigationStack {
            List {
                
                // MARK: - Language Section
                Section {
                    ForEach(LocalizationManager.Language.allCases, id: \.self) { language in
                        Button {
                            withAnimation {
                                localization.currentLanguage = language
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Text(language.flag)
                                    .font(.title2)
                                
                                Text(language.displayName)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                // Checkmark for selected language
                                if localization.currentLanguage == language {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(orangeColor)
                                        .font(.system(size: 20))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Text("settings_language".localized)
                }
                
                // MARK: - App Info Section
                Section {
                    HStack {
                        Text("Version")
                            .foregroundColor(.primary)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Developer")
                            .foregroundColor(.primary)
                        Spacer()
                        Text("Shubham Lakhotia")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("settings_title".localized)
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
