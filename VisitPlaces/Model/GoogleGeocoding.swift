// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let googleGeocoding = try? newJSONDecoder().decode(GoogleGeocoding.self, from: jsonData)

import Foundation

// MARK: - Geocoding
struct GoogleGeocoding: Codable {
    let results: [Geocoding]
    let status: String
}

// MARK: - ResultGeocoding
struct Geocoding: Codable {
    let geometry: Geometry
}
