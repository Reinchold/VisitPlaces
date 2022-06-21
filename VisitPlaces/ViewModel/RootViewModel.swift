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
    var fetcherViewController = WrapperFetcherViewController()

    // input
    @Published var cameraPosition: GMSCameraPosition?
    @Published var searchInput: String = ""
    @Published var placeID: String = ""
    @Published var recommendationID = "bar"
    @Published var locationRadius: Float = 200.0
    
    @Published var isShownSettingView = false
    @Published var isShownMapDetailView = false
    @Published var isShownAlert = false
    @Published var isShownSearchResultView = false
    @Published var keyboardHeight: CGFloat = .zero
    
    // output
    @Published var searchInputCheck: String = ""
    @Published var searchOutputs = [GMSAutocompletePrediction]()
    @Published var searchOutput: GMSAutocompletePrediction?
    @Published var interestPoints = [ResultPlaces]()
    @Published var articlesError: APIError?
    
    var isNeedsMapUpdate = false
    
    /// Reduce server requests
    private var validRecommendation: AnyPublisher<String, Never> {
        $recommendationID
            .debounce(for: 0.3, scheduler: RunLoop.main)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    private var validLocationRadius: AnyPublisher<Float, Never> {
        $locationRadius
            .debounce(for: 0.3, scheduler: RunLoop.main)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    private var cancellableSet: Set<AnyCancellable> = []
    
    init() {
        observePlaces()
        locationPlaceID()
    }
    
    func locationPlaceID()  {
        $cameraPosition
            .sink { position in
                if position == nil {
                    self.cameraPosition = GMSCameraPosition.berlin
                }
                self.isNeedsMapUpdate = true
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
                self.cameraPosition =  GMSCameraPosition.berlin
            } else {
                //show error
            }
        }
    }
    
    private func observePlaces() {
        Publishers.CombineLatest(validRecommendation, validLocationRadius)
            .setFailureType(to: APIError.self)
            .flatMap {  (point, radius) -> AnyPublisher<[ResultPlaces], APIError> in
                
                self.interestPoints = [ResultPlaces]()
                let item = String(Int(radius))
                return API.shared.fetchRecommendations(from: Endpoint.place(type: point, radius: item))
            }
            .sink(
                receiveCompletion: { [unowned self] (completion) in
                    if case let .failure(error) = completion {
                        self.articlesError = error
                    }},
                receiveValue: { [unowned self] in
                    self.interestPoints = $0
                    self.isNeedsMapUpdate = true
                })
            .store(in: &self.cancellableSet)
        
        $isShownSearchResultView
            .sink { text in
                print("text: \(text)")
            }
            .store(in: &self.cancellableSet)
        
        $searchOutputs
            .map {!$0.isEmpty }
            .assign(to: \.isShownSearchResultView, on: self)
            .store(in: &self.cancellableSet)
        
    }
    
    func getGeocoding() {
        API.shared.fetchPointDetail(from: Endpoint.geocode(address: searchInput))
            .sink(receiveCompletion: { [unowned self] (completion) in
                if case let .failure(error) = completion {
                    self.articlesError = error
                }},
                  receiveValue: { geocoding in
                guard let location = geocoding.map { $0.geometry.location }.first else { return }
                
                GMSCameraPosition.location = CLLocationCoordinate2D(latitude: location.lat,
                                                                    longitude: location.lng)
                self.cameraPosition =  GMSCameraPosition.berlin
                self.isNeedsMapUpdate = true
            })
            .store(in: &self.cancellableSet)
    }
}
