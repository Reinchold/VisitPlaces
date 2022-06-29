//
//  ImageSkeleton.swift
//  VisitPlaces
//
//  Created by Roman Vostrikov on 27.06.22.
//

import SwiftUI

struct ImageSkeleton: View {
    
    var image: UIImage
    
    var callback: ((UIImage) -> Void)?
    
    var body: some View {
        VStack {
           Image(uiImage: image) 
                .resizable()
                .scaledToFill()
                .clipped()
                .frame(width: 170, height: 170)
                .cornerRadius(10)
                .shadow(radius: 5)
        }.onTapGesture {
            withAnimation {
                callback?(image)
            }
        }
        .onAppear(perform: {
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 1).repeatForever()) {
                    
                }
            }
        })
    }
}
