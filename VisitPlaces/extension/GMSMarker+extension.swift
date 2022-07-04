//
//  GMSMarker+extension.swift
//  VisitPlaces
//
//  Created by Roman Vostrikov on 22.06.22.
//

import GoogleMaps

extension GMSMarker {
    
    func setIconSize(scaledToSize newSize: CGSize=CGSize(width: 35, height: 35)) {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        icon?.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        icon = newImage
    }
    
}
