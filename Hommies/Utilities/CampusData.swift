//
//  CampusData.swift
//  Hommies
//
//  Created by Shubham Lakhotia on 4/23/26.
//

import CoreLocation

// Campus coordinates for distance calculation
struct Campus {
    let name: String
    let coordinate: CLLocationCoordinate2D
    
    static let bostonUniversity = Campus(
        name: "Boston University",
        coordinate: CLLocationCoordinate2D(latitude: 42.3505, longitude: -71.1054)
    )
    
    static let northeastern = Campus(
        name: "Northeastern University",
        coordinate: CLLocationCoordinate2D(latitude: 42.3398, longitude: -71.0892)
    )
    
    static let all = [bostonUniversity, northeastern]
}

// Calculates distance between two coordinates in miles
func distanceBetween(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> String {
    let location1 = CLLocation(latitude: lat1, longitude: lon1)
    let location2 = CLLocation(latitude: lat2, longitude: lon2)
    
    // distanceInMeters gives distance in meters
    let distanceInMeters = location1.distance(from: location2)
    
    // Convert meters to miles
    let distanceInMiles = distanceInMeters / 1609.344
    
    if distanceInMiles < 0.1 {
        return "On campus"
    } else if distanceInMiles < 1.0 {
        return String(format: "%.1f miles", distanceInMiles)
    } else {
        return String(format: "%.1f miles", distanceInMiles)
    }
}
