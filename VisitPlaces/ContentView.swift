//
//  ContentView.swift
//  VisitPlaces
//
//  Created by Roman Vostrikov on 13.06.22.
//

import SwiftUI
import GoogleMaps

struct ContentView: View {
    
    @EnvironmentObject var rootViewModel: RootViewModel
    
    var body: some View {
        
        ZStack(alignment: .bottom) {
            // Left bar menu
            HStack {
                VStack(alignment: .leading, spacing: 12) {
                    SettingView()
                    Spacer(minLength: 0)
                }
                .padding(.top, 25)
                .padding(.horizontal, 20)
                
                Spacer(minLength: 0)
            }
            .padding(.top, UIApplication
                                .shared
                                .connectedScenes
                                .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
                                .first { $0.isKeyWindow }?.safeAreaInsets.top)
            .padding(.bottom, UIApplication
                                .shared
                                .connectedScenes
                                .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
                                .first { $0.isKeyWindow }?.safeAreaInsets.bottom)
            
            // MainView...
            ZStack(alignment: .top) {
                PlacesFetcher()
                GoogleMapsView(rootViewModel: rootViewModel, landmarks: $rootViewModel.interestPoints)
                
                HStack(spacing: 8) {
                    // Close Button...
                    Button(action: {
                        withAnimation {
                            self.rootViewModel.isShownSettingView.toggle()
                        }
                    }) {
                        Image(systemName: self.rootViewModel.isShownSettingView ? "xmark" : "line.horizontal.3")
                            .resizable()
                            .frame(width: self.rootViewModel.isShownSettingView ? 18 : 22, height: 18)
                            .scaledToFit()
                            .foregroundColor(Color.red.opacity(0.7))
                            .padding(SwiftUI.EdgeInsets(top: 18, leading: 12, bottom: 18, trailing: 12))
                            .background(.white)
                    }
                    .cornerRadius(8)
                    .shadow(radius: 3)
                    
                    SearchTextField()
                }
                .padding(.top, UIApplication
                    .shared
                    .connectedScenes
                    .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
                    .first { $0.isKeyWindow }?.safeAreaInsets.top)
                .padding()
                
                // Modal View - List
                ModalView(orientationShapeWidth: UIScreen.main.bounds.size.width,
                          modalHeight: 300) {
                        PlacesListView()
                }
                
            }
            
            .cornerRadius(self.rootViewModel.isShownSettingView ? 30 : 0)
            .scaleEffect(self.rootViewModel.isShownSettingView ? 0.9 : 1)
            .offset(x: self.rootViewModel.isShownSettingView ? UIScreen.main.bounds.width / 2 : 0,
                    y: self.rootViewModel.isShownSettingView ? 100 : 0)
            .rotationEffect(.init(degrees: self.rootViewModel.isShownSettingView ? -5 : 0))
            
        }
        .edgesIgnoringSafeArea(.all)
        
//        .alert(isPresented: $rootViewModel.showAlert) {
//            Alert(title: Text("Error"),
//                  message: Text(rootViewModel.articlesError?.localizedDescription ?? ""),
//                  dismissButton: .default(Text("OK"),
//                                          action: { rootViewModel.articlesError = nil }
//                  )
//            )
//        }
    }
    
    
}

