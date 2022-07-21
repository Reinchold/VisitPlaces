//
//  SearchField.swift
//  VisitPlaces
//
//  Created by Roman Vostrikov on 20.06.22.
//

import SwiftUI

struct SearchField: View {
    
    @EnvironmentObject var rootViewModel: RootViewModel
    
    var body: some View {
        Section {
            ZStack {
                HStack {
                    
                    // Show setting view button
                    Button(action: {
                        withAnimation {
                            self.rootViewModel.isShownSettingView.toggle()
                        }
                    }) {
                        Image(systemName: self.rootViewModel.isShownSettingView ? "xmark" : "line.horizontal.3")
                            .resizable()
                            .frame(width: self.rootViewModel.isShownSettingView ? 18 : 22, height: 18)
                            .scaledToFit()
                            .foregroundColor(VPColors.subTitle)
                    }
                    
                    // Search TextField
                    TextField("", text: $rootViewModel.searchTextField, onEditingChanged: { focused in
                        if focused {
                            rootViewModel.gmsPlace = nil
                        }
                    })
                        .placeholder(when: rootViewModel.searchTextField.isEmpty) {
                            Text("Enter address").foregroundColor(.accentColor).opacity(0.5)
                        }
                        .font(VPFonts.SFProTextRegular18)
                        .accentColor(VPColors.title)
                        .foregroundColor(VPColors.title)
                        .padding(.leading, 10)
                        .disabled(rootViewModel.isShownSettingView)
                        
                    // Delete text button
                    if rootViewModel.searchTextField != "" {
                        Image(systemName: "xmark.circle.fill")
                            .imageScale(.medium)
                            .foregroundColor(VPColors.subTitle)
                            .padding(3)
                            .onTapGesture {
                                withAnimation {
                                    rootViewModel.searchTextField = ""
                                }
                            }
                    }
                    
                    // Search button
                    Button(action: {
                        Task {
                            try? await rootViewModel.getGeocoding()
                        }
                        rootViewModel.autocompletePredictions.removeAll()
                    }, label: {
                        Image(systemName: "magnifyingglass")
                            .resizable()
                            .foregroundColor(VPColors.subTitle)
                            .shadow(color: Color.primary.opacity(0.3),
                                    radius: 5,
                                    x: 1,
                                    y: 1)
                            .aspectRatio(contentMode: .fit)
                    })
                    .buttonStyle(PlainButtonStyle())
                    .frame(width: 20, height: 20, alignment: .center)
                    .padding(.trailing, 10)
                }
                .padding(.all, 15)
                .background(VPColors.systemBackground)
                .cornerRadius(10)
                .shadow(radius: 3)
            }
        }
    }
}
