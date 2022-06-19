//
//  Notification+extension.swift
//  VisitPlaces
//
//  Created by Roman Vostrikov on 18.06.22.
//

import UIKit

extension Notification {
    var keyboardHeight: CGFloat {
        return (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
    }
}
