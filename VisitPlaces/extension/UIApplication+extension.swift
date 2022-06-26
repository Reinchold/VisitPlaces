//
//  UIApplication+extension.swift
//  VisitPlaces
//
//  Created by Roman Vostrikov on 25.06.22.
//

import UIKit

extension UIApplication {
    
    var safeAreaInsets: UIEdgeInsets? {
        let keyWindow = UIApplication
            .shared
            .connectedScenes
            .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
            .first { $0.isKeyWindow }
        
        return keyWindow?.safeAreaInsets
    }

}
