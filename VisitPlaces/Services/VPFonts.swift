//
//  VPFonts.swift
//  VisitPlaces
//
//  Created by Roman Vostrikov on 03.07.22.
//

import SwiftUI

// MARK: - Fonts

struct VPFonts {

    struct SFProText {
        static let regular: String = "SFProText-Regular"
        static let light: String = "SFProText-Light"
        static let heavy: String = "SFProText-Heavy"
    }
    
    static let SFProTextLight12 = Font.custom(SFProText.light, size: 12)
    static let SFProTextLight16 = Font.custom(SFProText.light, size: 16)
    static let SFProTextLight18 = Font.custom(SFProText.light, size: 18)
    
    static let SFProTextRegular12 = Font.custom(SFProText.regular, size: 12)
    static let SFProTextRegular16 = Font.custom(SFProText.regular, size: 16)
    static let SFProTextRegular18 = Font.custom(SFProText.regular, size: 18)

    static let SFProTextHeavy12 = Font.custom(SFProText.heavy, size: 12)
    static let SFProTextHeavy16 = Font.custom(SFProText.heavy, size: 16)
    static let SFProTextHeavy22 = Font.custom(SFProText.heavy, size: 22)
    
}
