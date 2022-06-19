//
//  API.swift
//  VisitPlaces
//
//  Created by Roman Vostrikov on 15.06.22.
//

/*
 https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=-33.8670522%2C151.1957362&radius=1500&type=restaurant&key=AIzaSyAypXKfnqbdPKOiH-i4G9WhfNawEfYPA2s
 https://maps.googleapis.com/maps/api/place/nearbysearch/json?place_id=ChIJZ4S6wMpLqEcRyYUJK3qxnEI&key=AIzaSyAypXKfnqbdPKOiH-i4G9WhfNawEfYPA2s
 
 */
import GoogleMaps
import Combine

enum Endpoint {
    case endpoint(type: String, radius: String)
    case detail(placeID: String)
    
    var baseURL:URL {URL(string: "https://maps.googleapis.com/maps/api/place/nearbysearch/json")!}
    
    var absoluteURL: URL? {
        let components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        guard var urlComponents = components else {
            return nil
        }
        switch self {
        case let .endpoint(type, radius):
            urlComponents.queryItems = [
                URLQueryItem(name: "location", value: "\(GMSCameraPosition.location.latitude),\(GMSCameraPosition.location.longitude)" ),
                URLQueryItem(name: "radius", value: radius),
                URLQueryItem(name: "type", value: type),
                URLQueryItem(name: "key", value: VPConstants.apiKey)
            ]
            
        case .detail(let placeID):
            urlComponents.queryItems = [
                URLQueryItem(name: "place_id", value: placeID),
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
    
    func fetchRecommendations(from endpoint: Endpoint) -> AnyPublisher<[Result], APIError> {
        Future<[Result], APIError> { [unowned self] promise in
            
            guard let url = endpoint.absoluteURL else {
                return promise(.failure(.urlError(URLError(.unsupportedURL))))
            }
//            print("💜: \(url)")
            self.fetchErr(url)
                .tryMap { (model: GoogleModel) -> [Result] in
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
    
//    func fetchPointDetail(from endpoint: Endpoint) -> AnyPublisher<DVenue, Never> {
//
//        guard let url = endpoint.absoluteURL else {
//            return Just(DVenue()).eraseToAnyPublisher()
//        }
//
//        return fetchErr(url)
//            .map { (response: DFoursquare) -> DResponse in
//                return  response.response! }
//            .map { (response: DResponse) -> DVenue in
//                return  response.venue ?? DVenue() }
//            .replaceError(with: DVenue())
//            .eraseToAnyPublisher()
//    }
    
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




