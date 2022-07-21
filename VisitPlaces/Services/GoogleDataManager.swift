//
//  GoogleDataManager.swift
//  VisitPlaces
//
//  Created by Roman Vostrikov on 21.07.22.
//

import GooglePlaces
import GoogleMaps
import Foundation

struct PlacePhoto: Identifiable, Hashable {
    let id: Int
    var photo: UIImage
    var attributedString: NSAttributedString?
}

class GoogleDataManager {
    
    private let placeClient = GMSPlacesClient()
   
    // MARK: - Autocomplete Prediction
    func getLatLongFromAutocompletePrediction(prediction: GMSAutocompletePrediction) async throws -> GMSPlace {
        return try await withCheckedThrowingContinuation { continuation in
            placeClient.lookUpPlaceID(prediction.placeID) { (place, error) -> Void in
                if let error = error {
                    print("An error occurred: \(error.localizedDescription)")
                    continuation.resume(throwing: APIError.placeDetails)
                    return
                }
                
                if let place = place {
                    continuation.resume(returning: place)
                }
            }
        }
    }
    
    func fetchPlace(_ markerPlaces: ResultPlaces) async throws -> GMSPlace {
        let name = UInt(GMSPlaceField.name.rawValue)
        let photos = UInt(GMSPlaceField.photos.rawValue)
        let rating = UInt(GMSPlaceField.rating.rawValue)
        let openingHours = UInt(GMSPlaceField.openingHours.rawValue)
        let addressComponents = UInt(GMSPlaceField.addressComponents.rawValue)
        let formattedAddress = UInt(GMSPlaceField.formattedAddress.rawValue)
        let businessStatus = UInt(GMSPlaceField.businessStatus.rawValue)
        
        let fields: GMSPlaceField = GMSPlaceField(rawValue: name | photos | rating | openingHours | addressComponents | formattedAddress | businessStatus)
        
        return try await withCheckedThrowingContinuation { continuation in
            placeClient.fetchPlace(fromPlaceID: markerPlaces.placeId, placeFields: fields, sessionToken: nil, callback: { (place: GMSPlace?, error: Error?) in
                if let error = error {
                    print("An error occurred: \(error.localizedDescription)")
                    continuation.resume(throwing: APIError.fetchPlace)
                    return
                }
                if let place = place {
                    continuation.resume(returning: place)
                }
            })
        }
    }
    
    func getPlacePhotos(photoMetadatas: [GMSPlacePhotoMetadata]) async throws -> [PlacePhoto] {
        return try await withThrowingTaskGroup(of: PlacePhoto?.self, body: { group in
            var placePhotos: [PlacePhoto] = []
            placePhotos.reserveCapacity(photoMetadatas.count)
            
            for (index, photoMetadata) in photoMetadatas.enumerated() {
                group.addTask { await self.loadPlacePhoto(photoMetadata, index: index) }
            }
            
            for try await placePhoto in group {
                if let placePhoto = placePhoto {
                    placePhotos.append(placePhoto)
                }
            }
            
            return placePhotos
        })
    }
    
    private func loadPlacePhoto(_ photoMetadata: GMSPlacePhotoMetadata, index: Int) async -> PlacePhoto? {
        return await withCheckedContinuation { continuation in
            // Call loadPlacePhoto to display the bitmap and attribution.
            self.placeClient.loadPlacePhoto(photoMetadata, callback: { (image, error) -> Void in
                if let error = error {
                    print("Error loading photo metadata: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }
                
                if let image = image {
                    continuation.resume(returning: PlacePhoto(id: index, photo: image, attributedString: photoMetadata.attributions))
                }
            })
        }
    }
}
