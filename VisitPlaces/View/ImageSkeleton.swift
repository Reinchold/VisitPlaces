//
//  ImageSkeleton.swift
//  VisitPlaces
//
//  Created by Roman Vostrikov on 27.06.22.
//

import SwiftUI

struct ImageSkeleton: View {
    
    var image: UIImage
    var gradient = [Color.white, Color.black]
    
    @State var isAktive: Bool = false
    @State var start = UnitPoint(x: 0, y: 0.5)
    @State var end = UnitPoint(x: 1, y: 0.5)
    
    var callback: ((UIImage) -> Void)?
    
    var gradientFill: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: self.gradient),
            startPoint: self.start,
            endPoint: self.end
        )
    }
    
    var body: some View {
        
        VStack {
            if isAktive {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .onTapGesture {
                        callback?(image)
                    }
            } else {
                Rectangle()
                    .fill(gradientFill)
                    .opacity(0.1)
                    .animation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: start)
                    .onAppear {
                        self.start = UnitPoint(x: -1, y: 0.5)
                        self.end = UnitPoint(x: 0, y: 0.5)
                    }
            }
        }
        .frame(width: 160, height: 160)
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.vertical)
        .onAppear {
            Task {
                try await Task.sleep(seconds: 1)
                await MainActor.run(body: {
                    withAnimation {
                        isAktive.toggle()
                    }
                })
            }
        }
    }
}
