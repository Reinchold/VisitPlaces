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
                            .foregroundColor(Color.red.opacity(0.9))
                    }
                    
                    // Search TextField
                    TextField("", text: $rootViewModel.searchTextField)
                        .placeholder(when: rootViewModel.searchTextField.isEmpty) {
                            Text("Enter address").foregroundColor(.red).opacity(0.5)
                        }
                        .font(.title3)
                        .accentColor(.red)
                        .foregroundColor(.red)
                        .padding(.leading, 10)
                        .disabled(rootViewModel.isShownSettingView)
                        
                    // Delete text button
                    if rootViewModel.searchTextField != "" {
                        Image(systemName: "xmark.circle.fill")
                            .imageScale(.medium)
                            .foregroundColor(Color.red.opacity(0.7))
                            .padding(3)
                            .onTapGesture {
                                withAnimation {
                                    rootViewModel.searchTextField = ""
                                }
                            }
                    }
                    
                    // Search button
                    Button(action: {
                        rootViewModel.getGeocoding()
                        rootViewModel.isShownAutocompletePredictions = false
                    }, label: {
                        Image(systemName: "magnifyingglass")
                            .resizable()
                            .foregroundColor(Color.red.opacity(0.9))
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
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 3)
            }
        }
    }
}
