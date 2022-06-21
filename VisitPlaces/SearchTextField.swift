//
//  SearchTextField.swift
//  VisitPlaces
//
//  Created by Roman Vostrikov on 20.06.22.
//

import SwiftUI

struct SearchTextField: View {
    
    @EnvironmentObject var rootViewModel: RootViewModel
    
    var body: some View {
        Section {
            ZStack {
                HStack {
                    // Search TextField
                    TextField("", text: $rootViewModel.searchInput)
                        .placeholder(when: rootViewModel.searchInput.isEmpty) {
                            Text("Enter address").foregroundColor(.red).opacity(0.5)
                        }
                        .font(.title3)
                        .accentColor(.red)
                        .foregroundColor(.red)
                        
                    
                    if rootViewModel.searchInput != "" {
                        Image(systemName: "xmark.circle.fill")
                            .imageScale(.medium)
                            .foregroundColor(Color(.systemGray3))
                            .padding(3)
                            .onTapGesture {
                                withAnimation {
                                    rootViewModel.searchInput = ""
                                }
                            }
                    }
                    
                    Button(action: {
                        rootViewModel.getGeocoding()
                        rootViewModel.isShownSearchResultView = false
                    }, label: {
                        Image(systemName: "magnifyingglass")
                            .resizable()
                            .foregroundColor(Color.secondary)
                            .shadow(color: Color.primary.opacity(0.3),
                                    radius: 5,
                                    x: 1,
                                    y: 1)
                            .aspectRatio(contentMode: .fit)
                    })
                    .buttonStyle(PlainButtonStyle())
                    .frame(width: 30, height: 40, alignment: .center)
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
