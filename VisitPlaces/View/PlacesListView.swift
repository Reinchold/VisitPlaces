//
//  PlacesListView.swift
//  VisitPlaces
//
//  Created by Roman Vostrikov on 17.06.22.
//

import SwiftUI
import GooglePlaces

struct PlacesListView: View {
    
    @EnvironmentObject var rootViewModel: RootViewModel
    
    var body: some View {
 
            List {
                ForEach(rootViewModel.autocompletePredictions, id: \.self) { index in
                    Button(action: {
                        rootViewModel.getLatLongFromAutocompletePrediction(prediction: index)
                        rootViewModel.autocompletePrediction = index
                        rootViewModel.searchTextField = index.attributedFullText.string
                        
                        Task {
                            try await Task.sleep(seconds: 1)
                            rootViewModel.endEditing()
                        }
                        
                    }) {
                        VStack(alignment: .leading) {
                            Text(index.attributedPrimaryText.string)
                                .font(VPFonts.SFProTextRegular16)
                                .foregroundColor(VPColors.title)
                            Text(index.attributedSecondaryText?.string ?? " ")
                                .font(VPFonts.SFProTextLight12)
                                .foregroundColor(VPColors.subTitle)
                        }
                    }
                }
            }
    }
}