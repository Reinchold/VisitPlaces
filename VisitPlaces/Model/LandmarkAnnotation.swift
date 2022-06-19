//
//  LandmarkAnnotation.swift
//  VisitPlaces
//
//  Created by Roman Vostrikov on 15.06.22.
//

import MapKit

final class LandmarkAnnotation: NSObject, MKAnnotation {
    var title: String?
    var subtitle: String?
    var coordinate: CLLocationCoordinate2D
    var icon: UIImage
    
    init(title: String?, subtitle: String?, coordinate: CLLocationCoordinate2D, icon: UIImage) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
        self.icon = icon
    }
}
