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
    
    // GoogleMaps markers
    var markers: [GMSMarker] = []
    
    // input
    @Published var searchTextField: String = ""
    @Published var searchTextFieldCheck: String = ""

    @Published var cameraPosition: GMSCameraPosition?
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
    
        
    init() {
        locationPlaceID()
        observePlaces()
    }
    
    func locationPlaceID()  {
        $cameraPosition
            .sink { position in
                if position == nil {
                    self.cameraPosition = GMSCameraPosition.cameraPosition
                }
            }
            .store(in: &self.cancellableSet)
    }
    
    func getLatLongFromAutocompletePrediction(prediction: GMSAutocompletePrediction) {
        let placeClient = GMSPlacesClient()
        placeClient.lookUpPlaceID(prediction.placeID) { (place, error) -> Void in
            if let error = error {
                 //show error
                return
            }

            if let place = place {
                GMSCameraPosition.location = CLLocationCoordinate2D(latitude: place.coordinate.latitude,
                                                                    longitude: place.coordinate.longitude)
                self.cameraPosition =  GMSCameraPosition.cameraPosition
            } else {
                //show error
            }
        }
    }
    
    private func observePlaces() {
        Publishers.CombineLatest3(searchTypePublisher, locationRadiusPublisher, $cameraPosition)
            .setFailureType(to: APIError.self)
            .flatMap { (point, radius, _) -> AnyPublisher<[ResultPlaces], APIError> in
                self.resultPlaces = [ResultPlaces]()
                let item = String(Int(radius))
                return API.shared.fetchRecommendations(from: Endpoint.place(type: point, radius: item))
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
                    
                    GMSCameraPosition.location = CLLocationCoordinate2D(latitude: location.lat,
                                                                        longitude: location.lng)
                    self.cameraPosition =  GMSCameraPosition.cameraPosition
                })
            .store(in: &self.cancellableSet)
    }
}

// MARK: - AnyPublisher

extension RootViewModel {
    
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
    
}

