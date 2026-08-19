//
//  API.swift
//  MatchMate
//
//  Created by Sahana N B on 19/08/26.
//

import Foundation

struct RandomUserResponse: Decodable {
    let results: [RandomUserDTO]
}

struct RandomUserDTO: Decodable {
    let gender: String
    let name: NameDTO
    let location: LocationDTO
    let email: String
    let login: LoginDTO
    let dob: DateDTO
    let registered: DateDTO
    let phone: String
    let nat: String
    let picture: PictureDTO
}

struct NameDTO: Decodable { let title: String; let first: String; let last: String }
struct LoginDTO: Decodable { let uuid: String }
struct PictureDTO: Decodable { let large: URL; let medium: URL }
struct DateDTO: Decodable { let date: Date }

struct LocationDTO: Decodable {
    let city: String
    let state: String
    let country: String
}

enum APIError: LocalizedError {
    case invalidResponse
    case server(Int)
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidResponse: "The server returned an invalid response."
        case .server(let code): "Server returned HTTP \(code)."
        case .noData: "No profiles were returned."
        }
    }
}

protocol ProfileAPI: Sendable {
    func fetchProfiles(page: Int, results: Int) async throws -> [Profile]
}

struct RandomUserAPI: ProfileAPI {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchProfiles(page: Int, results: Int = 10) async throws -> [Profile] {
        var components = URLComponents(string: "https://randomuser.me/api/")!
        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "results", value: String(results)),
            URLQueryItem(name: "seed", value: "matchmate")
        ]

        let (data, response) = try await session.data(from: components.url!)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.server(http.statusCode) }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(RandomUserResponse.self, from: data)
        guard !payload.results.isEmpty else { throw APIError.noData }

        return payload.results.map {
            Profile(
                id: $0.login.uuid,
                title: $0.name.title,
                firstName: $0.name.first,
                lastName: $0.name.last,
                email: $0.email,
                phone: $0.phone,
                nationality: $0.nat,
                gender: $0.gender,
                dateOfBirth: $0.dob.date,
                registeredDate: $0.registered.date,
                city: $0.location.city,
                state: $0.location.state,
                country: $0.location.country,
                largePhotoURL: $0.picture.large,
                mediumPhotoURL: $0.picture.medium
            )
        }
    }
}
