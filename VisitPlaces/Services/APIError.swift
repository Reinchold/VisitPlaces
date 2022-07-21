//
//  APIError.swift
//  VisitPlaces
//
//  Created by Roman Vostrikov on 15.06.22.
//

import Foundation

enum APIError: Error {
    case decode
    case invalidURL
    case noResponse
    case unexpectedStatusCode(Int)
    case imageDownload
    case fetchPlace
    case placeDetails
    case unknown
    
    var errorDescription: String {
        switch self {
        case .decode:
            return "The context in which the error occurred."
        case .invalidURL:
            return "The invalid URL Path error."
        case .noResponse:
            return "The Web Service server can supply the data."
        case .unexpectedStatusCode (let code):
            return "Unexpected status code: \(code)"
        case .unknown:
            return "An unknown error occurred."
        case .imageDownload:
            return "There was a problem uploading photos."
        case .fetchPlace:
            return "Location could not be loaded."
        case .placeDetails:
            return "Detailed location description could not be loaded."
        }
    }
    
}
