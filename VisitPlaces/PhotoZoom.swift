//
//  PhotoZoom.swift
//  VisitPlaces
//
//  Created by Roman Vostrikov on 26.06.22.
//

import SwiftUI

struct PhotoZoom: View {
    
    @State var scale: CGFloat = 1
    @State var scaleAnchor: UnitPoint = .center
    @State var lastScale: CGFloat = 1
    @State var offset: CGSize = .zero
    @State var lastOffset: CGSize = .zero
    @State var debug = ""
    
    @EnvironmentObject var rootViewModel: RootViewModel
    
    var body: some View {
        GeometryReader { geometry in
            let magnificationGesture = MagnificationGesture()
                .onChanged{ gesture in
                    scaleAnchor = .center
                    scale = lastScale * gesture
                }
                .onEnded { _ in
                    fixOffsetAndScale(geometry: geometry)
                }
            
            let dragGesture = DragGesture()
                .onChanged { gesture in
                    var newOffset = lastOffset
                    newOffset.width += gesture.translation.width
                    newOffset.height += gesture.translation.height
                    offset = newOffset
                }
                .onEnded { _ in
                    fixOffsetAndScale(geometry: geometry)
                }
            
            Image(uiImage: rootViewModel.zoomImage ?? UIImage())
                .resizable()
                .scaledToFit()
                .position(x: geometry.size.width / 2,
                          y: geometry.size.height / 2)
                .scaleEffect(scale, anchor: scaleAnchor)
                .offset(offset)
                .gesture(dragGesture)
                .gesture(magnificationGesture)
            
            Button(action: { rootViewModel.zoomImage = nil }) {
                ZStack {
                    Image(systemName: "circle.fill")
                        .foregroundColor(Color.secondary)
                        .font(.system(size: 31))
                    
                    Image(systemName: "xmark")
                        .foregroundColor(Color.white)
                        .font(.system(size: 15, weight: .bold))
                }
            }
            .foregroundColor(.white)
            .frame(width: 35, height: 35)
            .position(x: geometry.size.width * 0.9,
                      y: geometry.size.height - (geometry.size.height * 0.9))
        }
        .background(Color.primary)
        .edgesIgnoringSafeArea(.all)
        
    }
    
    private func fixOffsetAndScale(geometry: GeometryProxy) {
        
        guard let image = rootViewModel.zoomImage else { return }
        
        let newScale: CGFloat = .minimum(.maximum(scale, 1), 4)
        let screenSize = geometry.size
        
        let originalScale = image.size.width / image.size.height >= screenSize.width / screenSize.height ?
            geometry.size.width / image.size.width :
            geometry.size.height / image.size.height
        
        let imageWidth = (image.size.width * originalScale) * newScale
        
        var width: CGFloat = .zero
        if imageWidth > screenSize.width {
            let widthLimit: CGFloat = imageWidth > screenSize.width ?
                (imageWidth - screenSize.width) / 2
                : 0

            width = offset.width > 0 ?
                .minimum(widthLimit, offset.width) :
                .maximum(-widthLimit, offset.width)
        }
        
        let imageHeight = (image.size.height * originalScale) * newScale
        var height: CGFloat = .zero
        if imageHeight > screenSize.height {
            let heightLimit: CGFloat = imageHeight > screenSize.height ?
                (imageHeight - screenSize.height) / 2
                : 0

            height = offset.height > 0 ?
                .minimum(heightLimit, offset.height) :
                .maximum(-heightLimit, offset.height)
        }
        
        let newOffset = CGSize(width: width, height: height)
        lastScale = newScale
        lastOffset = newOffset
        withAnimation() {
            offset = newOffset
            scale = newScale
        }
    }
}
