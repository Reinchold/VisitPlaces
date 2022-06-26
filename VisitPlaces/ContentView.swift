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
    
    @State var scale: CGFloat = 1.0
    
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
            .padding(.top, UIApplication.shared.safeAreaInsets?.top)
            .padding(.bottom, UIApplication.shared.safeAreaInsets?.bottom)

            // MainView (Map)
            ZStack(alignment: .top) {
                PlacesFetcher()
                GoogleMapsView()
                 
                // window blocker
                if rootViewModel.isShownSettingView {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            withAnimation {
                                rootViewModel.isShownSettingView = false
                            }
                        }
                }
                
                // Search Field
                SearchField()
                    .padding(.top, UIApplication.shared.safeAreaInsets?.top)
                    .padding()
                    .ignoresSafeArea(.keyboard)
                
                // MARK: - Autocomplete Prediction
                ModalView(isShown: $rootViewModel.isShownAutocompleteModalView, orientationShapeWidth: UIScreen.main.bounds.size.width, modalHeight: 300) {
                    PlacesListView()
                } callback: {
                    rootViewModel.autocompletePredictions.removeAll()
                }

                // MARK: - Place Detail
                ModalView(isShown: $rootViewModel.isShownPlaceDetail, orientationShapeWidth: UIScreen.main.bounds.size.width, modalHeight: 300) {
                    PlacesDetailView()
                } callback: {
                    rootViewModel.gmsPlace = nil
                }

                // MARK: - Photo zoomer
                if rootViewModel.isShownPhotoZoom {
                    PhotoZoom()
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

