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
    @Published var searchOutput = [GMSAutocompletePrediction]()
    @Published var interestPoints = [Result]()
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
            .flatMap {  (point, radius) -> AnyPublisher<[Result], APIError> in
                
                self.interestPoints = [Result]()
                let item = String(Int(radius))
                return API.shared.fetchRecommendations(from: Endpoint.endpoint(type: point, radius: item))
            }
            .sink(
                receiveCompletion:  {[unowned self] (completion) in
                    if case let .failure(error) = completion {
//                        print("🍎: \(error)")
                        self.articlesError = error
                    }},
                receiveValue: { [unowned self] in
//                    print("☘️: \($0.count)")
                    self.interestPoints = $0
                    self.isNeedsMapUpdate = true
                })
            .store(in: &self.cancellableSet)
        
        $isShownSearchResultView
            .sink { text in
                print("text: \(text)")
            }
            .store(in: &self.cancellableSet)
        
        $searchOutput
            .map {!$0.isEmpty }
            .assign(to: \.isShownSearchResultView, on: self)
            .store(in: &self.cancellableSet)
        
    }
}
