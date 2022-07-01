//
//  GoogleMapsView.swift
//  VisitPlaces
//
//  Created by Roman Vostrikov on 13.06.22.
//
//  https://stackoverflow.com/questions/21021531/how-to-get-the-number-of-annotations-markers-in-a-visible-area-of-map-using-goog

import SwiftUI
import GoogleMaps
import GooglePlaces

struct GoogleMapsView: UIViewRepresentable {
    
    @EnvironmentObject var rootViewModel: RootViewModel
    
    private let angle: Double = 10
    private let bearing: CLLocationDirection = 10
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> GMSMapView {
        let camera = rootViewModel.cameraPosition
        let mapView = GMSMapView(frame: .zero, camera: camera)
        mapView.delegate = context.coordinator
        
        // Map style
        do {
            mapView.mapStyle = try GMSMapStyle(named: "style")
        } catch {
            NSLog("One or more of the map styles failed to load. \(error)")
        }

        return mapView
    }
    
    func updateUIView(_ mapView: GMSMapView, context: Context) {
        guard rootViewModel.isNeedsMapUpdate else { return }
        rootViewModel.isNeedsMapUpdate = false
                
        // Remove all markers
        rootViewModel.markers.removeAll()
        mapView.clear()
        
        // Add markers for Places of interest
        rootViewModel.resultPlaces.forEach {
            self.markerCreator(mapView, resultPlaces: $0)
        }
        
        // Add a marker for location of the found place
        markerCreator(mapView, resultPlaces: nil)
        
        // Change location if necessary
        moveCamera(mapView)
        
        fitBounds(mapView)
    }
    
    // MARK: - Marker Creator
    func markerCreator(_ mapView: GMSMapView, resultPlaces: ResultPlaces?) {
        var location: CLLocationCoordinate2D
        if let coordinate = resultPlaces?.geometry.location.coordinate {
            location = coordinate
        } else {
            location = rootViewModel.cameraPosition.target
        }
        
        let marker = GMSMarker(position: location)
        marker.appearAnimation = .pop
        marker.rotation = Double.random(in: -10...10)
        marker.icon = resultPlaces == nil ? UIImage(named: "search")! : UIImage(named: rootViewModel.searchType)!
        marker.userData = resultPlaces
        marker.setIconSize()
        rootViewModel.markers.append(marker)
        marker.map = mapView
    }
    
    // MARK: - Fit marker bounds
    func fitBounds(_ mapView: GMSMapView) {
        guard !rootViewModel.markers.isEmpty else { return }
        
        var bounds = GMSCoordinateBounds()
        for marker in rootViewModel.markers {
            bounds = bounds.includingCoordinate(marker.position)
        }
        guard bounds.isValid else { return }
        mapView.moveCamera(GMSCameraUpdate.fit(bounds, withPadding: 100))
    }
    
    // MARK: - Change location
    func moveCamera(_ mapView: GMSMapView) {
        let newPosition = rootViewModel.cameraPosition
        mapView.animate(to: newPosition)
    }
    
    final class Coordinator: NSObject, GMSMapViewDelegate {
        
        var parent: GoogleMapsView
        
        init(_ parent: GoogleMapsView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
            parent.rootViewModel.getPlaceDetails(marker)
            return false
        }
        
        func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
            parent.rootViewModel.gmsPlace = nil
            parent.rootViewModel.marker = nil
//            parent.rootViewModel.marker?.tracksInfoWindowChanges = false
        }
    }

}

