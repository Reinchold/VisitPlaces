//
//  Location.swift
//  VisitPlaces
//
//  Created by Roman Vostrikov on 13.06.22.
//

import Foundation
import UIKit
import SwiftUI
import GooglePlaces


struct PlacePicker: UIViewControllerRepresentable {
    
    let autocompleteController = GMSAutocompleteViewController()
    @Environment(\.presentationMode) var presentationMode
    @Binding var address: String

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<PlacePicker>) -> GMSAutocompleteViewController {
        
        autocompleteController.delegate = context.coordinator
    
        let fields: GMSPlaceField = GMSPlaceField(rawValue: UInt(GMSPlaceField.name.rawValue) |
          UInt(GMSPlaceField.placeID.rawValue))
        autocompleteController.placeFields = fields

        let filter = GMSAutocompleteFilter()
        filter.type = .address
        filter.country = "DE"
        autocompleteController.autocompleteFilter = filter
        
        return autocompleteController
    }

    func updateUIViewController(_ uiViewController: GMSAutocompleteViewController, context: UIViewControllerRepresentableContext<PlacePicker>) {
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, GMSAutocompleteViewControllerDelegate {

        var parent: PlacePicker

        init(_ parent: PlacePicker) {
            self.parent = parent
        }

        func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
            DispatchQueue.main.async {
                print("🏛: ", place.description.description as Any)
                self.parent.address =  place.name!
                self.parent.presentationMode.wrappedValue.dismiss()
                self.parent.autocompleteController.reloadInputViews()
            }
        }

        func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
            print("Error: ", error.localizedDescription)
        }

        func wasCancelled(_ viewController: GMSAutocompleteViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }

    }
}
