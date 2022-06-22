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
    
    // GoogleMaps markers
    var markers: [GMSMarker] = []
    
    // input
    @Published var searchTextField: String = ""
    @Published var searchTextFieldCheck: String = ""

    @Published var cameraPosition: GMSCameraPosition?
    @Published var placeID: String = ""
    @Published var searchType = "bar"
    @Published var locationRadius: Float = 200.0
    
    @Published var isShownAutocompleteValid = false
    @Published var isShownSettingView = false
    @Published var isShownAutocompletePredictions = false
    @Published var isShownPlaceDetail = false
    @Published var keyboardHeight: CGFloat = .zero
    
    // output
    @Published var autocompletePredictions = [GMSAutocompletePrediction]()
    @Published var autocompletePrediction: GMSAutocompletePrediction?
    @Published var resultPlaces = [ResultPlaces]()
    @Published var articlesError: APIError?
    
    private var cancellableSet: Set<AnyCancellable> = []
    
    var isNeedsMapUpdate = false
        
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
        Publishers.CombineLatest3(validRecommendation, validLocationRadius, $cameraPosition)
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
        
        $autocompletePredictions
            .map {!$0.isEmpty }
            .assign(to: \.isShownAutocompletePredictions, on: self)
            .store(in: &self.cancellableSet)
        
        predictionsModalViewPublisher
            .receive(on: RunLoop.main)
            .map { $0 }
            .assign(to: \.isShownAutocompleteValid, on: self)
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

extension RootViewModel {
    
    // Reduce server requests
    private var validRecommendation: AnyPublisher<String, Never> {
        $searchType
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    private var validLocationRadius: AnyPublisher<Float, Never> {
        $locationRadius
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    var predictionsModalViewPublisher: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest($isShownAutocompletePredictions, $isShownSettingView)
            .receive(on: RunLoop.main)
            .map { $0 && !$1 }
            .eraseToAnyPublisher()
    }
    
}

