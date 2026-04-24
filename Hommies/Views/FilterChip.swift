//
//  FilterChip.swift
//  Hommies
//
//  Created by Shubham Lakhotia on 4/22/26.
//

import SwiftUI

struct FilterChip: View {
    
    let title: String
    let isSelected: Bool
    let color: Color
    
    var body: some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(isSelected ? .semibold : .regular)
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? color : Color(.secondarySystemBackground))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? color : Color(.systemGray4), lineWidth: 1)
            )
    }
}
