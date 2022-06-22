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
        let mapView = GMSMapView(frame: .zero, camera: camera!)
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
                
        /// Remove markers
        rootViewModel.markers.removeAll()
        mapView.clear()
        
        // Places of interest
        let newAnnotations = rootViewModel.resultPlaces.map {
            LandmarkAnnotation(title: $0.name,
                               subtitle: $0.vicinity,
                               coordinate: $0.geometry.location.coordinate,
                               icon: UIImage(named: rootViewModel.searchType)!)  }
        newAnnotations.forEach { self.markerCreator(mapView, annotation: $0) }
        
        // Location of the found place
        let location = GMSCameraPosition.location
        let annotation = LandmarkAnnotation(title: "", subtitle: "The place that I was looking for", coordinate: location, icon: UIImage(named: "search")!)
        markerCreator(mapView, annotation: annotation)
        
        // Change location if necessary
        moveCamera(mapView)
        
        fitBounds(mapView)
    }
    
    // MARK: - Marker Creator
    func markerCreator(_ mapView: GMSMapView, annotation: LandmarkAnnotation) {
        let marker = GMSMarker(position: annotation.coordinate)
        marker.title = annotation.title
        marker.snippet = annotation.subtitle
        marker.appearAnimation = .pop
        marker.rotation = Double.random(in: -10...10)
        marker.icon = annotation.icon
        marker.setIconSize(scaledToSize: .init(width: 35, height: 35))
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
        let newPosition = GMSCameraPosition(target: GMSCameraPosition.location, zoom: 15, bearing: 0, viewingAngle: 0)
        mapView.animate(to: newPosition)
    }
    
    final class Coordinator: NSObject, GMSMapViewDelegate {
        
        var parent: GoogleMapsView
        
        init(_ parent: GoogleMapsView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
            marker.setIconSize(scaledToSize: .init(width: 45, height: 45))
            return false
        }
        
        func mapView(_ mapView: GMSMapView, didCloseInfoWindowOf marker: GMSMarker) {
            marker.setIconSize(scaledToSize: .init(width: 35, height: 35))
            marker.tracksInfoWindowChanges = false
        }
    }

}
