//
//  NetworkManager.swift
//  BoxOffice
//
//  Created by vetto, brody on 23/03/20.
//
import Foundation

final class NetworkManager {
    func fetchData<T: Decodable>(
        for url: URL?,
        type: T.Type,
        completion: @escaping (Result<T, Error>) -> Void) {
        guard let url = url else {
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if error != nil {
                completion(.failure(NetworkError.unknownError))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return
            }
            
            guard (200...399).contains(httpResponse.statusCode) else {
                switch httpResponse.statusCode {
                case 400...499:
                    completion(.failure(NetworkError.clientError))
                case 500...599:
                    completion(.failure(NetworkError.serverError))
                default:
                    completion(.failure(NetworkError.unknownError))
                }
                
                return
            }
            
            if let mimeType = httpResponse.mimeType, mimeType == "application/json",
               let data = data {
                do {
                    let jsonData = try JSONDecoder().decode(type, from: data)
                    completion(.success(jsonData))
                } catch {
                    completion(.failure(error))
                }
                return
            }
        }
        
        task.resume()
    }
}
