//
//  CustomSliderView.swift
//  VisitPlaces
//
//  Created by Roman Vostrikov on 15.06.22.
//

import SwiftUI

struct CustomSliderView: View {
    
    @EnvironmentObject var rootViewModel: RootViewModel
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundColor(.secondary)
                Rectangle()
                    .foregroundColor(.accentColor)
                    .frame(width: geometry.size.width * CGFloat(rootViewModel.locationRadius / VPConstants.maxRadius))
            }
            .cornerRadius(12)
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged({ value in
                    let step = stepper(value.location.x, geometry.size.width, CGFloat(VPConstants.maxRadius))
                    rootViewModel.locationRadius = min(max(10, step), VPConstants.maxRadius)
                }))
        }
    }
    
    // FIXME: - improve data type
    func stepper(_ x: CGFloat, _ width: CGFloat, _ amount: CGFloat) -> Float {
        let position = x / width * amount
        return Float(VPConstants.radiusStep) * Float(lrint(position / VPConstants.radiusStep))
    }

}
