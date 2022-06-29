//
//  PlacesDetailView.swift
//  VisitPlaces
//
//  Created by Roman Vostrikov on 24.06.22.
//

import SwiftUI
import GooglePlaces

struct PlacesDetailView: View {
    
    @EnvironmentObject var rootViewModel: RootViewModel
    
    @State private var isDisclosed = false
    
    var callback: ((UIImage) -> Void)?
    
    var body: some View {
        
        let isOpenNow: Bool = {
            guard let markerPlaces = rootViewModel.marker?.userData as? ResultPlaces,
                  let openingHours = markerPlaces.openingHours?.openNow
            else { return false }
            return openingHours
        }()
        
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 10) {
                    
                    // Title
                    Text(rootViewModel.gmsPlace?.name ?? "")
                    HStack(spacing: 10) {
                        
                        // Rating
                        RatingStar(rating: rootViewModel.gmsPlace?.rating ?? .zero)
                        Text(String(format: "%.1f", rootViewModel.gmsPlace?.rating ?? 0))
                    }
                    
                    // Address
                    Text(rootViewModel.gmsPlace?.formattedAddress ?? "")
                }
                .padding(.horizontal, 20)
                
                // Opening hours with expand animation
                VStack(alignment: .leading, spacing: 0) {
//                    Text(openNow + (isDisclosed ? "" : "")).padding(5)
                    HStack {
                        Text(isOpenNow ? "Geöffnet" : "Geschlossen")
                            .foregroundColor(isOpenNow ? .green : .red)
                            .padding(5)

                        Image(systemName: isDisclosed ? "chevron.up" : "chevron.down")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 10, height: 10)
                    }
                
                    if let openingHours: [GMSPeriod] = rootViewModel.gmsPlace?.openingHours?.periods {
                        GroupBox {
                            VStack(alignment: .leading) {
                                ForEach(openingHours, id: \.self) { text in
                                    HStack {
                                        Text(Calendar.current.weekdaySymbols[Int(text.openEvent.day.rawValue) - 1])
                                        Spacer()
                                        Text(getTimePeriodString(from: text))
                                    }
                                }
                            }
                        }
                        .padding()
                        .frame(height: isDisclosed ? nil : 0, alignment: .top)
                        .clipped()                        
                    }
                }
                .frame(maxWidth: .infinity)
                .background(.thinMaterial)
                .cornerRadius(5)
                .padding()
                .onTapGesture {
                    withAnimation {
                        isDisclosed.toggle()
                    }
                }
                
                // Preview images
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .center, spacing: 20) {
                        ForEach(rootViewModel.placePhotos, id: \.self) { detail in
                            ImageSkeleton(image: detail.photo) { image in
                                rootViewModel.zoomImage = (image)
                            }
                        }
                    }
                    .padding(.horizontal, 15)
                }
            }
            .padding(.vertical, 20)
        }
    }
    
    func getTimePeriodString(from period: GMSPeriod) -> String {
        let startTime = period.openEvent.time
        
        var string = "\(startTime)"
        if let endTime = period.closeEvent?.time {
            string += " - \(endTime)"
        }
        return string
    }
    
}
