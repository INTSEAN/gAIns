//
//  Spotify.swift
//  gAIns
//
//  Created by SEAN DONOVAN on 11/14/24.
//

import Foundation

// MARK: - Spotify API Response Models

// Codable struct representing the overall structure of the Spotify API response.
struct SpotifyAPIResponse: Codable {
    let tracks: SpotifyTracks
}

// Codable struct representing the tracks section of the Spotify API response.
struct SpotifyTracks: Codable {
    let items: [SpotifyTrack]
}

// Codable struct representing an individual track in the Spotify API response.
struct SpotifyTrack: Codable {
    let album: SpotifyAlbum
    let external_urls: ExternalURLs

    // Codable struct representing external URLs associated with a Spotify track.
    struct ExternalURLs: Codable {
        let spotify: String
    }
}

// Codable struct representing album information in the Spotify API response.
struct SpotifyAlbum: Codable {
    let images: [SpotifyImage]
}

// Codable struct representing image information in the Spotify API response.
struct SpotifyImage: Codable {
    let url: String
}

// MARK: - Spotify Service

// A class responsible for interacting with the Spotify API to fetch track information.
class Spotify {
    
    // MARK: - Properties
    
    private static let clientId = "a530894e231446eca2bdbbf0441d206b"
    private static let clientSecret = "22f9a7eb55864dacac48c2fc52fb5029"
    private static var accessToken: String?
    private static var tokenExpirationDate: Date?
    
    // MARK: - Token Management
    
    private static func getAccessToken(completion: @escaping (Result<String, Error>) -> Void) {
        if let token = accessToken, let expirationDate = tokenExpirationDate,
           expirationDate > Date() {
            completion(.success(token))
            return
        }
        
        let auth = "\(clientId):\(clientSecret)".data(using: .utf8)!.base64EncodedString()
        
        guard let url = URL(string: "https://accounts.spotify.com/api/token") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Basic \(auth)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "grant_type=client_credentials".data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: 0, userInfo: nil)))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(TokenResponse.self, from: data)
                accessToken = response.access_token
                tokenExpirationDate = Date().addingTimeInterval(TimeInterval(response.expires_in))
                completion(.success(response.access_token))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Fetch Spotify Info
    
    static func fetchSpotifyInfo(for query: String, completion: @escaping (Result<SpotifyTrack, Error>) -> Void) {
        getAccessToken { result in
            switch result {
            case .success(let token):
                performSpotifySearch(query: query, token: token, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private static func performSpotifySearch(query: String, token: String, completion: @escaping (Result<SpotifyTrack, Error>) -> Void) {
        let formattedQuery = query.replacingOccurrences(of: " ", with: "%20")
        
        guard let url = URL(string: "https://api.spotify.com/v1/search?q=\(formattedQuery)&type=track") else {
            return completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                return completion(.failure(error))
            }
            
            guard let data = data else {
                return completion(.failure(NSError(domain: "No data received", code: 0, userInfo: nil)))
            }
            
            do {
                print(String(data: data, encoding: .utf8) ?? "Invalid data")
                
                let decodedResponse = try JSONDecoder().decode(SpotifyAPIResponse.self, from: data)
                if let track = decodedResponse.tracks.items.first {
                    completion(.success(track))
                } else {
                    completion(.failure(NSError(domain: "No track found", code: 0, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// MARK: - Token Response Model

private struct TokenResponse: Codable {
    let access_token: String
    let token_type: String
    let expires_in: Int
}
