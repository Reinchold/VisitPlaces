//
//  GMSMapStyle+extension.swift
//  VisitPlaces
//
//  Created by Roman Vostrikov on 21.06.22.
//

import GoogleMaps

extension GMSMapStyle {
    
    convenience init?(named fileName: String) throws {
        guard let styleURL = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            return nil
        }
        try self.init(contentsOfFileURL: styleURL)
    }
    
}
