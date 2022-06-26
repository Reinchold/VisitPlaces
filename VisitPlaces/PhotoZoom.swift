//
//  PhotoZoom.swift
//  VisitPlaces
//
//  Created by Roman Vostrikov on 25.06.22.
//

import SwiftUI

struct PhotoZoom: View {
    
    @EnvironmentObject var rootViewModel: RootViewModel
    
    @State var scale: CGFloat = 1.0
    
    var body: some View {
        VStack {
            // Shoew zoomed
            Image(uiImage: rootViewModel.zoomImage ?? UIImage())
                .resizable()
                .aspectRatio(contentMode: .fill)
                .scaleEffect(scale)
                .gesture(MagnificationGesture()
                    .onChanged { value in
                        self.scale = value.magnitude
                    }
                )
        }
    }
}

