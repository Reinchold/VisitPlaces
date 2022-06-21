// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let googlePlaces = try? newJSONDecoder().decode(GooglePlaces.self, from: jsonData)

import Foundation
import MapKit

// MARK: - Res
struct GooglePlaces: Codable {
    let results: [ResultPlaces]
    let status: String
}

// MARK: - Result
struct ResultPlaces: Codable {
    let businessStatus: String?
    let geometry: Geometry
    let icon: String
    let iconBackgroundColor: String
    let iconMaskBaseURI: String?
    let name: String
    let openingHours: OpeningHours?
    let photos: [Photo]?
    let placeID: String?
    let plusCode: PlusCode?
    let priceLevel: Int?
    let rating: Double?
    let reference, scope: String
    let types: [String]
    let userRatingsTotal: Int?
    let vicinity: String
}

// MARK: - Geometry
struct Geometry: Codable {
    let location: Location
    let viewport: Viewport
}

// MARK: - Location
struct Location: Codable {
    var id: String? = UUID().uuidString
    let lat, lng: Double
    
    init() {
        self.lat = .zero
        self.lng = .zero
    }
}

// MARK: - Equatable Location 

extension Location: Equatable  {
    static func ==(lhs: Location, rhs: Location) -> Bool {
        lhs.id == rhs.id
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}

// MARK: - Viewport
struct Viewport: Codable {
    let northeast, southwest: Location
}

// MARK: - OpeningHours
struct OpeningHours: Codable {
    let openNow: Bool
}

// MARK: - Photo
struct Photo: Codable {
    let height: Int
    let htmlAttributions: [String]
    let photoReference: String
    let width: Int
}

// MARK: - PlusCode
struct PlusCode: Codable {
    let compoundCode, globalCode: String
}
