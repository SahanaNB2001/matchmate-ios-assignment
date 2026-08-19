//
//  Models.swift
//  MatchMate
//
//  Created by Sahana N B on 19/08/26.
//

import Foundation
import SwiftData

struct Profile: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let title: String
    let firstName: String
    let lastName: String
    let email: String
    let phone: String
    let nationality: String
    let gender: String
    let dateOfBirth: Date?
    let registeredDate: Date?
    let city: String
    let state: String
    let country: String
    let largePhotoURL: URL?
    let mediumPhotoURL: URL?

    var fullName: String { "\(title) \(firstName) \(lastName)" }
    var location: String { "\(city), \(state), \(country)" }
}

enum MatchStatus: String, Codable, CaseIterable, Sendable {
    case pending
    case accepted
    case declined

    var title: String {
        switch self {
        case .pending: "Pending"
        case .accepted: "Accepted"
        case .declined: "Declined"
        }
    }
}

@Model
final class ProfileEntity {
    @Attribute(.unique) var id: String
    var title: String
    var firstName: String
    var lastName: String
    var email: String
    var phone: String
    var nationality: String
    var gender: String
    var dateOfBirth: Date?
    var registeredDate: Date?
    var city: String
    var state: String
    var country: String
    var largePhotoURL: String?
    var mediumPhotoURL: String?
    var statusRawValue: String
    var page: Int
    var cachedAt: Date
    var location: String { "\(city), \(state), \(country)" }

    init(profile: Profile, page: Int, status: MatchStatus = .pending) {
        self.id = profile.id
        self.title = profile.title
        self.firstName = profile.firstName
        self.lastName = profile.lastName
        self.email = profile.email
        self.phone = profile.phone
        self.nationality = profile.nationality
        self.gender = profile.gender
        self.dateOfBirth = profile.dateOfBirth
        self.registeredDate = profile.registeredDate
        self.city = profile.city
        self.state = profile.state
        self.country = profile.country
        self.largePhotoURL = profile.largePhotoURL?.absoluteString
        self.mediumPhotoURL = profile.mediumPhotoURL?.absoluteString
        self.statusRawValue = status.rawValue
        self.page = page
        self.cachedAt = Date()
    }

    var status: MatchStatus {
        get { MatchStatus(rawValue: statusRawValue) ?? .pending }
        set { statusRawValue = newValue.rawValue }
    }

    func asProfile() -> Profile {
        Profile(
            id: id,
            title: title,
            firstName: firstName,
            lastName: lastName,
            email: email,
            phone: phone,
            nationality: nationality,
            gender: gender,
            dateOfBirth: dateOfBirth,
            registeredDate: registeredDate,
            city: city,
            state: state,
            country: country,
            largePhotoURL: largePhotoURL.flatMap(URL.init(string:)),
            mediumPhotoURL: mediumPhotoURL.flatMap(URL.init(string:))
        )
    }
}
