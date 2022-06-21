//
//  PlacesFetcher.swift
//  VisitPlaces
//
//  Created by Roman Vostrikov on 17.06.22.
//  https://developers.google.com/maps/documentation/places/ios-sdk/autocomplete#get_place_predictions

import SwiftUI
import GooglePlaces

class WrapperFetcherViewController: UIViewController {
    var fetcher: GMSAutocompleteFetcher?
}

struct PlacesFetcher: UIViewControllerRepresentable {
    
    @EnvironmentObject var rootViewModel: RootViewModel
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> WrapperFetcherViewController {
        // Set up the autocomplete filter.
        let filter = GMSAutocompleteFilter()
        filter.type = .address
        filter.country = "DE"

        // Create a new session token.
        let token: GMSAutocompleteSessionToken = GMSAutocompleteSessionToken.init()

        // Create the fetcher.
        rootViewModel.fetcherViewController.fetcher = GMSAutocompleteFetcher(filter: filter)
        rootViewModel.fetcherViewController.fetcher?.delegate = context.coordinator
        rootViewModel.fetcherViewController.fetcher?.provide(token)
        return rootViewModel.fetcherViewController
    }

    func updateUIViewController(_ uiViewController: WrapperFetcherViewController, context: Context) {
        guard !rootViewModel.searchInput.isEmpty else {
            if !rootViewModel.searchOutputs.isEmpty {
                rootViewModel.searchOutputs.removeAll()
                rootViewModel.searchInputCheck.removeAll()
            }
            return
        }
        rootViewModel.fetcherViewController.fetcher?.sourceTextHasChanged(rootViewModel.searchInput)
    } 

    class Coordinator: NSObject, GMSAutocompleteFetcherDelegate {

        var parent: PlacesFetcher

        init(_ parent: PlacesFetcher) {
            self.parent = parent
            
        }

        func didAutocomplete(with predictions: [GMSAutocompletePrediction]) {
            guard parent.rootViewModel.searchInput != parent.rootViewModel.searchInputCheck else { return }
            parent.rootViewModel.searchOutputs = predictions
            parent.rootViewModel.searchInputCheck = parent.rootViewModel.searchInput
        }
        
        func didFailAutocompleteWithError(_ error: Error) {
            print("💚")
        }

    }
}
