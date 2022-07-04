//
//  RootViewModel.swift
//  VisitPlaces
//
//  Created by Roman Vostrikov on 13.06.22.
//

import Combine
import GooglePlaces
import GoogleMaps
import SwiftUI

struct PlacePhotos: Identifiable, Hashable {
    let id: Int
    var photo: UIImage
    var attributedString: NSAttributedString?
}

final class RootViewModel: ObservableObject {
    
    // GMSAutocompleteFetcher wrapped to UIViewController
    let fetcherViewController = WrapperFetcherViewController()
    
    // GoogleMaps markers
    var markers: [GMSMarker] = []
    var marker: GMSMarker?
    
    var isNeedsMapUpdate = false
    
    private let placeClient = GMSPlacesClient()
    @Published var userInterfaceStyle: UIUserInterfaceStyle = .light
    @Published var mapView = GMSMapView()
    
    // input
    @Published var searchTextField: String = ""
    @Published var searchTextFieldCheck: String = ""
    
    @Published var cameraPosition: GMSCameraPosition = GMSCameraPosition.cameraPosition
    @Published var searchType = "bar"
    @Published var locationRadius: Float = 300.0
    
    @Published var isShownSettingView = false
    @Published var isShownAutocompleteModalView = false
    @Published var isShownPlaceDetail = false
    @Published var isShownPhotoZoom = false
    @Published var isOpeningHoursDisclosed = false
    
    @Published var keyboardHeight: CGFloat = .zero
    
    // output
    @Published var autocompletePredictions = [GMSAutocompletePrediction]()
    @Published var autocompletePrediction: GMSAutocompletePrediction?
    @Published var resultPlaces = [ResultPlaces]()
    @Published var gmsPlace: GMSPlace?
    @Published var placePhotos: [PlacePhotos] = []
    @Published var zoomImage: UIImage?
    private let imageCache = NSCache<NSString, NSData>()
    
    @Published var articlesError: APIError?
    
    private var cancellableSet: Set<AnyCancellable> = []
    
    // Reduce server requests
    private var searchTypePublisher: AnyPublisher<String, Never> {
        $searchType
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    private var locationRadiusPublisher: AnyPublisher<Float, Never> {
        $locationRadius
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    init() {
        observePlaces()
    }
    
    private func observePlaces() {
        $zoomImage
            .map { $0 != nil }
            .assign(to: \.isShownPhotoZoom, on: self)
            .store(in: &cancellableSet)
        
        $gmsPlace
            .map { $0 != nil }
            .sink(receiveValue: { [unowned self] state in
                if state {
                    self.marker?.setIconSize(scaledToSize: .init(width: 45, height: 45))
                } else {
                    self.marker?.setIconSize()
                    self.marker = nil
                }
                self.isOpeningHoursDisclosed = false
                self.isShownPlaceDetail = state
            })
            .store(in: &cancellableSet)
        
        Publishers.CombineLatest3(searchTypePublisher, locationRadiusPublisher, $cameraPosition)
            .setFailureType(to: APIError.self)
            .flatMap { (point, radius, position) -> AnyPublisher<[ResultPlaces], APIError> in
                self.resultPlaces = [ResultPlaces]()
                let item = String(Int(radius))
                let coordinate = "\(position.target.latitude),\(position.target.longitude)"
                return API.shared.fetchRecommendations(from: Endpoint.place(type: point, radius: item, coordinate: coordinate))
            }
            .sink(
                receiveCompletion: { [unowned self] (completion) in
                    if case let .failure(error) = completion {
                        self.articlesError = error
                    }},
                receiveValue: { [unowned self] in
                    self.resultPlaces = $0
                    self.isNeedsMapUpdate = true
                })
            .store(in: &self.cancellableSet)
        
        Publishers.CombineLatest($autocompletePredictions, $isShownSettingView)
            .receive(on: RunLoop.main)
            .map { !$0.isEmpty && !$1 }
            .assign(to: \.isShownAutocompleteModalView, on: self)
            .store(in: &cancellableSet)
    }
    
}

// MARK: - Places handle

extension RootViewModel {
    
    func getGeocoding() {
        API.shared.fetchPointDetail(from: Endpoint.geocode(address: searchTextField))
            .sink(
                receiveCompletion: { [unowned self] (completion) in
                    if case let .failure(error) = completion {
                        self.articlesError = error
                    }
                }, receiveValue: { geocoding in
                    guard let location = geocoding.map({ $0.geometry.location }).first else { return }
                    
                    self.cameraPosition = GMSCameraPosition(latitude: location.lat, longitude: location.lng, zoom: 15)
                })
            .store(in: &self.cancellableSet)
    }
    
    // MARK: - Autocomplete Prediction
    func getLatLongFromAutocompletePrediction(prediction: GMSAutocompletePrediction) {
        placeClient.lookUpPlaceID(prediction.placeID) { (place, error) -> Void in
            if let error = error {
                //show error
                return
            }
            
            if let place = place {
                self.cameraPosition = GMSCameraPosition(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude, zoom: 15)
            } else {
                //show error
            }
        }
    }
    
    func endEditing() {
        // End text editing
        UIApplication.shared.keyWindow?.endEditing(true)
        autocompletePredictions.removeAll()
    }
    
    // MARK: - Place Details (get information about a place)
    func getPlaceDetails(_ marker: GMSMarker) {
        endEditing()
        
        guard self.marker != marker else { return }
        guard let markerPlaces = marker.userData as? ResultPlaces else { return }
        if self.marker != nil {
            self.placePhotos.removeAll()
            self.marker?.setIconSize()
        }
        self.marker = marker
        
        let name = UInt(GMSPlaceField.name.rawValue)
        let photos = UInt(GMSPlaceField.photos.rawValue)
        let rating = UInt(GMSPlaceField.rating.rawValue)
        let openingHours = UInt(GMSPlaceField.openingHours.rawValue)
        let addressComponents = UInt(GMSPlaceField.addressComponents.rawValue)
        let formattedAddress = UInt(GMSPlaceField.formattedAddress.rawValue)
        let businessStatus = UInt(GMSPlaceField.businessStatus.rawValue)
        
        let fields: GMSPlaceField = GMSPlaceField(rawValue: name | photos | rating | openingHours | addressComponents | formattedAddress | businessStatus)
        
        placeClient.fetchPlace(fromPlaceID: markerPlaces.placeId, placeFields: fields, sessionToken: nil, callback: { (place: GMSPlace?, error: Error?) in
            if let error = error {
                print("An error occurred: \(error.localizedDescription)")
                return
            }
            if let place = place {
                self.gmsPlace = place
                guard let photoMetadata = place.photos else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.getPlacePhotos(photoMetadatas: photoMetadata)
                }
            }
        })
    }
    
    private func getPlacePhotos(photoMetadatas: [GMSPlacePhotoMetadata]) {
        DispatchQueue.global(qos: .userInitiated).async {
            var photos: [PlacePhotos] = []
            let group = DispatchGroup()
            
            for (index, photoMetadata) in photoMetadatas.enumerated() {
                group.enter()
                
                // Call loadPlacePhoto to display the bitmap and attribution.
                self.placeClient.loadPlacePhoto(photoMetadata, callback: { (image, error) -> Void in
                    
                    if let error = error {
                        // TODO: Handle the error.
                        print("Error loading photo metadata: \(error.localizedDescription)")
                    }
                    
                    if let image = image {
                        photos.append(PlacePhotos(id: index, photo: image, attributedString: photoMetadata.attributions))
                    }
                    group.leave()
                })
            }
            
            group.wait()
            
            group.notify(queue: .main) {
                let photosSorted = photos.sorted(by: { $0.id < $1.id })
                
                for (n, obj) in photosSorted.enumerated() {
                    let sec = Double(n) * 0.1
                    DispatchQueue.main.asyncAfter(deadline: .now() + sec) {
                        self.placePhotos.append(obj)
                    }
                }
            }
        }
    }
    
}

