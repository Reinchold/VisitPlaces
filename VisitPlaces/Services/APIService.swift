//
//  API.swift
//  VisitPlaces
//
//  Created by Roman Vostrikov on 15.06.22.
//

import GoogleMaps
import Combine

enum Endpoint {
    case place(type: String, radius: String, coordinate: String)
    case geocode(address: String)
    
    var baseURL: URL? { URL(string: "https://maps.googleapis.com/maps/api") }
    
    func path() -> String {
        switch self {
        case .place:
            return "place/nearbysearch/json"
        case .geocode:
            return "geocode/json"
        }
    }
    
    var absoluteURL: URL? {
        guard let queryURL = baseURL?.appendingPathComponent(self.path()) else {
            return nil
        }
        let components = URLComponents(url: queryURL, resolvingAgainstBaseURL: true)
        guard var urlComponents = components else {
            return nil
        }
        switch self {
        case let .place(type, radius, position):
            urlComponents.queryItems = [
                URLQueryItem(name: "location", value: position),
                URLQueryItem(name: "radius", value: radius),
                URLQueryItem(name: "type", value: type),
                URLQueryItem(name: "key", value: VPConstants.apiKey)
            ]
            
        case .geocode(let address):
            urlComponents.queryItems = [
                URLQueryItem(name: "address", value: address),
                URLQueryItem(name: "key", value: VPConstants.apiKey)
            ]
        }
        return urlComponents.url
    }
}

class APIService {
    
    static func getPointDetail(from endpoint: Endpoint) async throws -> GoogleGeocoding {
        guard let url = endpoint.absoluteURL else {
            throw APIError.invalidURL
        }
        return try await fetch(from: url)
    }
    
    static func getRecommendation(from endpoint: Endpoint) async throws -> GooglePlaces {
        guard let url = endpoint.absoluteURL else {
            throw APIError.invalidURL
        }
        return try await fetch(from: url)
    }
    
    private static func fetch<D: Decodable>(from url: URL) async throws -> D {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            return try handleResponse(data: data, response: response)
        } catch {
            throw error
        }
    }
    
    private static func handleResponse<D: Decodable>(data: Data, response: URLResponse) throws -> D {
        guard let response = response as? HTTPURLResponse else {
            throw APIError.noResponse
        }
        
        guard 200...299 ~= response.statusCode else {
            throw APIError.unexpectedStatusCode(response.statusCode)
        }
        
        do {
            let jsonDecoder = JSONDecoder()
            jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
            return try jsonDecoder.decode(D.self, from: data)
        } catch {
            throw APIError.decode
        }
    }
    
}
