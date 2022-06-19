//
//  VisitPlacesApp.swift
//  VisitPlaces
//
//  Created by Roman Vostrikov on 13.06.22.
//

import SwiftUI
import GooglePlaces
import GoogleMaps

@main
struct VisitPlacesApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(RootViewModel())
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate    {
     func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
         GMSServices.provideAPIKey(VPConstants.apiKey)
         GMSPlacesClient.provideAPIKey(VPConstants.apiKey)
         
         return true
     }
 }
