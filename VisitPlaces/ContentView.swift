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
    @Environment(\.colorScheme) var colorScheme
    @State var scale: CGFloat = 1.0
    
    var fontColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var body: some View {
        
        GeometryReader { geometry in
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
                    .frame(width: geometry.size.width*0.9)
                    .padding(.top, UIApplication.shared.safeAreaInsets?.top)
                
                // MARK: - Autocomplete Prediction
                ModalView(isShown: $rootViewModel.isShownAutocompleteModalView, midHeight: 300, width: geometry.size.width) {
                    PlacesListView()
                } callback: {
                    withAnimation {
                        rootViewModel.autocompletePredictions.removeAll()
                    }
                }
                
                // MARK: - Place Detail
                ModalView(isShown: $rootViewModel.isShownPlaceDetail, midHeight: 300, width: geometry.size.width, isFullScreenable: true) {
                    PlacesDetailView()
                } callback: {
                    rootViewModel.gmsPlace = nil
                }

                // MARK: - Photo zoomer
                ZStack {
                    if rootViewModel.isShownPhotoZoom {
                        PhotoZoom()
                    }
                }
                .transition(.slide)
            }
            .cornerRadius(self.rootViewModel.isShownSettingView ? 30 : 0)
            .scaleEffect(self.rootViewModel.isShownSettingView ? 0.9 : 1)
            .offset(x: self.rootViewModel.isShownSettingView ? UIScreen.main.bounds.width / 2 : 0,
                    y: self.rootViewModel.isShownSettingView ? 100 : 0)
            .rotationEffect(.init(degrees: self.rootViewModel.isShownSettingView ? -5 : 0))

        }
        .edgesIgnoringSafeArea(.all)
        .onChange(of: colorScheme) { mode in
            let style = mode == .light ? "style-light" : "style-dark"

            do {
                rootViewModel.mapView.mapStyle = try GMSMapStyle(named: style)
            } catch {
                NSLog("One or more of the map styles failed to load. \(error)")
            }
        }
        
        .alert(isPresented: $rootViewModel.isAlertShown) {
            Alert(title: Text("Fehler"),
                  message: Text(rootViewModel.articlesError?.errorDescription ?? ""),
                  dismissButton: .default(Text("OK"), action: { rootViewModel.articlesError = nil })
            )
        }
    }
    
}

