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
    
    enum IconType {
        case icon
        case iconView
    }
    
    @ObservedObject var rootViewModel: RootViewModel
    @Binding var landmarks: [ResultPlaces]
    
    private let angle: Double = 10
    private let bearing: CLLocationDirection = 10
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> GMSMapView {
        let camera = rootViewModel.cameraPosition
        let mapView = GMSMapView(frame: .zero, camera: camera!)
        mapView.delegate = context.coordinator
        
        // style
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
        mapView.clear()
        
        // Places of interest
        // GMSMarker.markerImage(with: UIColor(hue: CGFloat.random(in: 0..<1), saturation: 1, brightness: 1, alpha: 1))
        let newAnnotations = landmarks.map {
            LandmarkAnnotation(title: $0.name,
                               subtitle: $0.vicinity,
                               coordinate: $0.geometry.location.coordinate,
                                      icon: UIImage(named: rootViewModel.recommendationID)!)  }
        newAnnotations.forEach { self.markerCreator(mapView, annotation: $0, iconType: .iconView) }
        
        // Location of the found place
        let location = GMSCameraPosition.location
        let annotation = LandmarkAnnotation(title: "", subtitle: "The place that I was looking for", coordinate: location, icon: GMSMarker.markerImage(with: UIColor.red))
        markerCreator(mapView, annotation: annotation, iconType: .icon)
        
        // Change location if necessary
        moveCamera(mapView)
    }
    
    // MARK: - Marker Creator
    func markerCreator(_ mapView: GMSMapView, annotation: LandmarkAnnotation, iconType: IconType) {
        let marker = GMSMarker(position: annotation.coordinate)
        marker.title = annotation.title
        marker.snippet = annotation.subtitle
        marker.appearAnimation = .pop
        marker.rotation = Double.random(in: -10...10)
        
        switch iconType {
        case .icon:
            marker.icon = annotation.icon
        case .iconView:
            let imageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: 35, height: 35)))
            imageView.image = annotation.icon.withRenderingMode(.alwaysOriginal)
            marker.iconView = imageView
        }
        
        marker.map = mapView
    }
    
    // MARK: - Change location
    func moveCamera(_ mapView: GMSMapView) {
        let newPosition = GMSCameraPosition(
            target: GMSCameraPosition.location, zoom: 15, bearing: 0, viewingAngle: 0)
        mapView.animate(to: newPosition)
        
        print("coordinate: \(GMSCameraPosition.location)")
    }
    
    final class Coordinator: NSObject, GMSMapViewDelegate {
        var parent: GoogleMapsView
        let infoMarker = GMSMarker()
        
        init(_ parent: GoogleMapsView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: GMSMapView, didTapPOIWithPlaceID placeID: String, name: String, location: CLLocationCoordinate2D) {
            infoMarker.snippet = placeID
            infoMarker.position = location
            infoMarker.title = name
            infoMarker.opacity = 0;
            infoMarker.infoWindowAnchor.y = 1
            infoMarker.map = mapView
            mapView.selectedMarker = infoMarker
            print("😀: \(placeID)")
            parent.rootViewModel.placeID = name
        }
    }

}

extension GMSMapStyle {
    convenience init?(named fileName: String) throws {
        guard let styleURL = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            return nil
        }
        try self.init(contentsOfFileURL: styleURL)
    }
}
