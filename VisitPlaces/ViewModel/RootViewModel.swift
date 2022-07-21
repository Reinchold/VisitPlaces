//
//  RootViewModel.swift
//  VisitPlaces
//
//  Created by Roman Vostrikov on 13.06.22.
//

import GooglePlaces
import GoogleMaps
import Combine
import SwiftUI

final class RootViewModel: ObservableObject {
    
    // GMSAutocompleteFetcher wrapped to UIViewController
    let fetcherViewController = WrapperFetcherViewController()
    let dataManager: GoogleDataManager
    
    // GoogleMaps markers
    var markers: [GMSMarker] = []
    var marker: GMSMarker?
    
    var isNeedsMapUpdate = false
    
    
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
    @Published var isAlertShown = false
    
    @Published var keyboardHeight: CGFloat = .zero
    
    // output
    @Published var autocompletePredictions = [GMSAutocompletePrediction]()
    @Published var autocompletePrediction: GMSAutocompletePrediction?
    @Published var resultPlaces = [ResultPlaces]()
    @Published var gmsPlace: GMSPlace?
    @MainActor @Published var placePhotos: [PlacePhoto] = []
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
    
    init(dataManager: GoogleDataManager = GoogleDataManager()) {
        self.dataManager = dataManager
        addSubscribers()
        Task {
           try await addPlacesSubscriber()
        }
    }
    
    private func addPlacesSubscriber() async throws {
        Task {
            for await (point, radius, position) in Publishers.CombineLatest3(searchTypePublisher, locationRadiusPublisher, $cameraPosition).values {
                do {
                    let item = String(Int(radius))
                    let coordinate = "\(position.target.latitude),\(position.target.longitude)"
                    let output = try await APIService.getRecommendation(from: Endpoint.place(type: point, radius: item, coordinate: coordinate))
                   
                    await MainActor.run(body: {
                        self.resultPlaces = output.results
                        self.isNeedsMapUpdate = true
                    })
                } catch let error as APIError {
                    await MainActor.run(body: {
                        self.articlesError = error
                    })
                }
            }
        }
    }
    
    private func addSubscribers() {
        $articlesError
            .map { $0 != nil }
            .assign(to: \.isAlertShown, on: self)
            .store(in: &cancellableSet)
        
        $zoomImage
            .map { $0 != nil }
            .assign(to: \.isShownPhotoZoom, on: self)
            .store(in: &cancellableSet)
        
        $gmsPlace
            .receive(on: DispatchQueue.main)
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
        
        Publishers.CombineLatest($autocompletePredictions, $isShownSettingView)
            .receive(on: RunLoop.main)
            .map { !$0.isEmpty && !$1 }
            .assign(to: \.isShownAutocompleteModalView, on: self)
            .store(in: &cancellableSet)
    }
    
}

// MARK: - Places handle

extension RootViewModel {
    
    func endEditing() async {
        // End text editing
        await MainActor.run(body: {
            UIApplication.shared.keyWindow?.endEditing(true)
            autocompletePredictions.removeAll()
        })
    }
    
    func getGeocoding() async throws {
        do {
            let geocoding = try await APIService.getPointDetail(from: Endpoint.geocode(address: searchTextField))
            guard let location = geocoding.results.map({ $0.geometry.location }).first else {
                return
            }
            self.cameraPosition = GMSCameraPosition(latitude: location.lat, longitude: location.lng, zoom: 15)
        } catch let error as APIError {
            await MainActor.run(body: {
                self.articlesError = error
            })
        }
    }
    
    func getLocation(prediction: GMSAutocompletePrediction) async throws {
        do {
            let place = try await dataManager.getLatLongFromAutocompletePrediction(prediction: prediction)
            self.cameraPosition = GMSCameraPosition(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude, zoom: 15)
        } catch let error as APIError {
            await MainActor.run(body: {
                self.articlesError = error
            })
        }
    }
    
    // MARK: - Place Details (get information about a place)
    func getPlaceDetails(_ marker: GMSMarker) async throws {
        await endEditing()
        
        guard self.marker != marker else { return }
        guard let markerPlaces = marker.userData as? ResultPlaces else { return }
        if self.marker != nil {
            await MainActor.run(body: {
                self.placePhotos.removeAll()
                self.marker?.setIconSize()
            })
        }
        self.marker = marker
        
        do {
            let place = try await dataManager.fetchPlace(markerPlaces)
            await MainActor.run(body: {
                self.gmsPlace = place
            })
            
            guard let photoMetadata = place.photos else { return }
            try await Task.sleep(seconds: 2)
            let photos = try await self.dataManager.getPlacePhotos(photoMetadatas: photoMetadata)
            let photosSorted = photos.sorted(by: { $0.id < $1.id })
            
            for (n, obj) in photosSorted.enumerated() {
                let sec = Double(n) * 0.1
                try await Task.sleep(seconds: sec)
                await MainActor.run(body: {
                    self.placePhotos.append(obj)
                })
            }
        } catch let error as APIError {
            await MainActor.run(body: {
                self.articlesError = error
                self.marker = nil
            })
        }
    }
}

