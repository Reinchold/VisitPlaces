//
//  API.swift
//  VisitPlaces
//
//  Created by Roman Vostrikov on 15.06.22.
//

/*
 https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=-33.8670522%2C151.1957362&radius=1500&type=restaurant&key=AIzaSyAypXKfnqbdPKOiH-i4G9WhfNawEfYPA2s
 https://maps.googleapis.com/maps/api/place/nearbysearch/json?place_id=ChIJZ4S6wMpLqEcRyYUJK3qxnEI&key=AIzaSyAypXKfnqbdPKOiH-i4G9WhfNawEfYPA2s
 https://maps.googleapis.com/maps/api/geocode/json?address=1600+Amphitheatre+Parkway,+Mountain+View,+CA&key=AIzaSyAypXKfnqbdPKOiH-i4G9WhfNawEfYPA2s
 */
import GoogleMaps
import Combine

enum Endpoint {
    case place(type: String, radius: String)
    case geocode(address: String)
    
    var baseURL: URL { URL(string: "https://maps.googleapis.com/maps/api")! }
    
    func path() -> String {
        switch self {
        case .place:
            return "place/nearbysearch/json"
        case .geocode:
            return "geocode/json"
        }
    }
    var absoluteURL: URL? {
        let queryURL = baseURL.appendingPathComponent(self.path())
        let components = URLComponents(url: queryURL, resolvingAgainstBaseURL: true)
        guard var urlComponents = components else {
            return nil
        }
        switch self {
        case let .place(type, radius):
            urlComponents.queryItems = [
                URLQueryItem(name: "location", value: "\(GMSCameraPosition.location.latitude),\(GMSCameraPosition.location.longitude)" ),
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

struct APIConstants {
    
    
    static let jsonDecoder: JSONDecoder = {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-mm-dd"
        jsonDecoder.dateDecodingStrategy = .formatted(dateFormatter)
        return jsonDecoder
    }()
}


class API {
    
    public static let shared = API()
    private var subscriptions = Set<AnyCancellable>()
    
    func fetchRecommendations(from endpoint: Endpoint) -> AnyPublisher<[ResultPlaces], APIError> {
        Future<[ResultPlaces], APIError> { [unowned self] promise in
            
            guard let url = endpoint.absoluteURL else {
                return promise(.failure(.urlError(URLError(.unsupportedURL))))
            }
            
            self.fetchErr(url)
                .tryMap { (model: GooglePlaces) -> [ResultPlaces] in
                    let results = model.results
                    return results }
                .sink(
                    receiveCompletion: { (completion) in
                        if case let .failure(error) = completion {
                            switch error {
                            case let urlError as URLError:
                                promise(.failure(.urlError(urlError)))
                            case let decodingError as DecodingError:
                                promise(.failure(.decodingError(decodingError)))
                            case let apiError as APIError:
                                promise(.failure(apiError))
                            default:
                                promise(.failure(.genericError))
                            }
                        }
                    },
                    receiveValue: { promise(.success($0)) })
                .store(in: &self.subscriptions)
        }
        .eraseToAnyPublisher()
    }
    
    /// Fetch detailed information about the selected location
    
    func fetchPointDetail(from endpoint: Endpoint) -> AnyPublisher<[Geocoding], APIError> {
        Future<[Geocoding], APIError> { [unowned self] promise in
            guard let url = endpoint.absoluteURL else {
                return promise(.failure(.urlError(URLError(.unsupportedURL))))
            }
            return fetchErr(url)
                .tryMap { (model: GoogleGeocoding) -> [Geocoding] in
                    let results = model.results
                    return results }
                .sink(
                    receiveCompletion: { (completion) in
                        if case let .failure(error) = completion {
                            switch error {
                            case let urlError as URLError:
                                promise(.failure(.urlError(urlError)))
                            case let decodingError as DecodingError:
                                promise(.failure(.decodingError(decodingError)))
                            case let apiError as APIError:
                                promise(.failure(apiError))
                            default:
                                promise(.failure(.genericError))
                            }
                        }
                    },
                    receiveValue: { promise(.success($0)) })
                .store(in: &self.subscriptions)
            
        }.eraseToAnyPublisher()
        
//            .map { (response: GoogleGeocoding) -> [Geocoding] in
//                if response.results.isEmpty {
//                    return Just([])
//                }
//                return  response.results }
//            .map { (response: [Geocoding]) -> Geocoding in
//                return  response.first! }
//            .map { (response: Geocoding) -> Geometry in
//                return  response.geometry }
//            .map { (response: Geometry) -> Location in
//                return  response.location }
//            .replaceError(with: Location())
//            .eraseToAnyPublisher()
    }
    
    func fetchErr<T: Decodable>(_ url: URL) -> AnyPublisher<T, Error> {
        URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { (data, response) -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                      200...299 ~= httpResponse.statusCode else {
                    throw APIError.responseError (
                        ((response as? HTTPURLResponse)?.statusCode ?? 500,
                         String(data: data, encoding: .utf8) ?? ""))
                }
                return data
            }
            .decode(type: T.self, decoder: APIConstants.jsonDecoder)
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    
}




