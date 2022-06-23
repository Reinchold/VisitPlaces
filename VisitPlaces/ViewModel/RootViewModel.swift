//
//  RootViewModel.swift
//  VisitPlaces
//
//  Created by Roman Vostrikov on 13.06.22.
//

import Combine
import GooglePlaces
import GoogleMaps

final class RootViewModel: ObservableObject {
    
    // GMSAutocompleteFetcher wrapped to UIViewController
    let fetcherViewController = WrapperFetcherViewController()
    
    var isNeedsMapUpdate = false
    
    let placeClient = GMSPlacesClient()
    
    // GoogleMaps markers
    var markers: [GMSMarker] = []
    
    // input
    @Published var searchTextField: String = ""
    @Published var searchTextFieldCheck: String = ""

    @Published var cameraPosition: GMSCameraPosition = GMSCameraPosition.cameraPosition
    @Published var searchType = "bar"
    @Published var locationRadius: Float = 200.0
    
    @Published var isShownAutocompleteModalView = false
    @Published var isShownSettingView = false
    @Published var isShownPlaceDetail = false
    
    @Published var keyboardHeight: CGFloat = .zero
    
    // output
    @Published var autocompletePredictions = [GMSAutocompletePrediction]()
    @Published var autocompletePrediction: GMSAutocompletePrediction?
    @Published var resultPlaces = [ResultPlaces]()
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
}

// MARK: - Places handle

extension RootViewModel {
    
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
    
    // https://developers.google.com/maps/documentation/places/ios-sdk/place-details
    // MARK: - Place Details
    func placeDetails(_ placeID: String?) {
        guard let placeID = placeID else { return }
        // A hotel in Saigon with an attribution.
//        let placeID = "ChIJV4k8_9UodTERU5KXbkYpSYs"
        // Specify the place data types to return.
        let fields: GMSPlaceField = GMSPlaceField(rawValue: UInt(GMSPlaceField.name.rawValue) | UInt(GMSPlaceField.placeID.rawValue))

        placeClient.fetchPlace(fromPlaceID: placeID, placeFields: fields, sessionToken: nil, callback: {
            (place: GMSPlace?, error: Error?) in
            if let error = error {
                print("An error occurred: \(error.localizedDescription)")
                return
            }
            if let place = place {
                print("The selected place is: \(place.name)")
            }
        })
    }
    
    // MARK: - Place Photos
    func placePhotos(_ placeID: String?) {
        guard let placeID = placeID else { return }
        // Specify the place data types to return (in this case, just photos).
        let fields: GMSPlaceField = GMSPlaceField(rawValue: UInt(GMSPlaceField.photos.rawValue))
        
        placeClient.fetchPlace(fromPlaceID: placeID, placeFields: fields, sessionToken: nil, callback: {
            (place: GMSPlace?, error: Error?) in
            if let error = error {
                print("An error occurred: \(error.localizedDescription)")
                return
            }
            if let place = place {
                // Get the metadata for the first photo in the place photo metadata list.
                let photoMetadata: GMSPlacePhotoMetadata = place.photos![0]
                
                // Call loadPlacePhoto to display the bitmap and attribution.
                self.placeClient.loadPlacePhoto(photoMetadata, callback: { (photo, error) -> Void in
                    if let error = error {
                        // TODO: Handle the error.
                        print("Error loading photo metadata: \(error.localizedDescription)")
                        return
                    } else {
                        // Display the first image and its attributions.
                        print("The selected image is: \(photo)")
                        print("The selected attributedText is: \(photoMetadata.attributions)")
//                        self.imageView?.image = photo;
//                        self.lblText?.attributedText = photoMetadata.attributions;
                    }
                })
            }
        })
    }
    
}

