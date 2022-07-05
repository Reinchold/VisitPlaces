//
//  VPConstants.swift
//  VisitPlaces
//
//  Created by Roman Vostrikov on 14.06.22.
//

import GoogleMaps

enum VPConstants {
    
//    #error("Register for API Key and insert here. Then delete this line.")
    static let apiKey = "AIzaSyC1v30lHI6NaFeS1qtdu4S4GroQF3KVx-s"
    static let maxRadius: Float = 1000
    static let radiusStep: CGFloat = 10
}

extension GMSCameraPosition  {
    static var berlin = CLLocationCoordinate2D(latitude: 52.521992, longitude: 13.413244)
    static var cameraPosition = GMSCameraPosition.camera(withTarget: berlin, zoom: 15, bearing: 0, viewingAngle: 0)
}
