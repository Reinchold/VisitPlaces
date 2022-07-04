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
                        .font(VPFonts.SFProTextHeavy22)
                        .foregroundColor(VPColors.title)
                    
                    HStack(spacing: 10) {
                        
                        // Rating
                        RatingStar(rating: rootViewModel.gmsPlace?.rating ?? .zero)
                        Text(String(format: "%.1f", rootViewModel.gmsPlace?.rating ?? 0))
                            .font(VPFonts.SFProTextRegular16)
                            .foregroundColor(VPColors.subTitle)
                    }
                    
                    // Address
                    Text(rootViewModel.gmsPlace?.formattedAddress ?? "")
                        .font(VPFonts.SFProTextLight12)
                        .foregroundColor(VPColors.subTitle)
                }
                .padding(.horizontal, 20)
                
                // Opening hours with expand animation
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text(isOpenNow ? "Geöffnet" : "Geschlossen")
                            .font(VPFonts.SFProTextRegular16)
                            .foregroundColor(isOpenNow ? .green : .red)
                            .padding(5)

                        Image(systemName: rootViewModel.isOpeningHoursDisclosed ? "chevron.up" : "chevron.down")
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
                                            .font(VPFonts.SFProTextLight16)
                                        Spacer()
                                        Text(getTimePeriodString(from: text))
                                            .font(VPFonts.SFProTextLight16)
                                    }
                                    .foregroundColor(VPColors.title)
                                }
                            }
                        }
                        .padding()
                        .frame(height: rootViewModel.isOpeningHoursDisclosed ? nil : 0, alignment: .top)
                        .clipped()                        
                    }
                }
                .frame(maxWidth: .infinity)
                .background(.thinMaterial)
                .cornerRadius(5)
                .padding()
                .onTapGesture {
                    withAnimation {
                        rootViewModel.isOpeningHoursDisclosed.toggle()
                    }
                }
                
                // Preview images
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .center, spacing: 20) {
                        ForEach(rootViewModel.placePhotos, id: \.self) { detail in
                            ImageSkeleton(image: detail.photo) { image in
                                withAnimation {
                                    rootViewModel.zoomImage = image
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 15)
                }
            }
            .padding(.vertical, 20)
        }
        .background(VPColors.systemBackground)
        .frame(maxHeight: rootViewModel.gmsPlace == nil ? .zero : .infinity)
    }
    
    // Convert TimePeriod to string
    func getTimePeriodString(from period: GMSPeriod) -> String {
        let startTime = period.openEvent.time
        
        var string = "\(startTime)"
        if let endTime = period.closeEvent?.time {
            string += " - \(endTime)"
        }
        return string
    }
    
}
