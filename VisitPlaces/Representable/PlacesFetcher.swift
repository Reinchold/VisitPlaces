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
        guard !rootViewModel.searchTextField.isEmpty
        else {
            if !rootViewModel.autocompletePredictions.isEmpty {
                rootViewModel.autocompletePredictions.removeAll()
                rootViewModel.searchTextFieldCheck.removeAll()
            }
            return
        }
        rootViewModel.fetcherViewController.fetcher?.sourceTextHasChanged(rootViewModel.searchTextField)
    } 

    class Coordinator: NSObject, GMSAutocompleteFetcherDelegate {

        var parent: PlacesFetcher

        init(_ parent: PlacesFetcher) {
            self.parent = parent
            
        }

        func didAutocomplete(with predictions: [GMSAutocompletePrediction]) {
            guard parent.rootViewModel.searchTextField != parent.rootViewModel.searchTextFieldCheck else { return }
            parent.rootViewModel.autocompletePredictions = predictions
            parent.rootViewModel.searchTextFieldCheck = parent.rootViewModel.searchTextField
        }
        
        func didFailAutocompleteWithError(_ error: Error) {
        }

    }
}
