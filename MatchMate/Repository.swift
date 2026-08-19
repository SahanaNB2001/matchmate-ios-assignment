//
//  Repository.swift
//  MatchMate
//
//  Created by Sahana N B on 19/08/26.
//

import Foundation
import SwiftData

@MainActor
final class ProfileRepository {
    private let api: ProfileAPI
    private let modelContainer: ModelContainer

    init(api: ProfileAPI, modelContainer: ModelContainer) {
        self.api = api
        self.modelContainer = modelContainer
    }

    private var context: ModelContext { ModelContext(modelContainer) }

    func fetchPage(page: Int, results: Int = 10) async throws {
        let profiles = try await api.fetchProfiles(page: page, results: results)
        let context = context

        for profile in profiles {
            let id = profile.id
            let descriptor = FetchDescriptor<ProfileEntity>(
                predicate: #Predicate { $0.id == id }
            )
            if let existing = try context.fetch(descriptor).first {
                let currentStatus = existing.status
                let pageNumber = page
                existing.title = profile.title
                existing.firstName = profile.firstName
                existing.lastName = profile.lastName
                existing.email = profile.email
                existing.phone = profile.phone
                existing.nationality = profile.nationality
                existing.gender = profile.gender
                existing.dateOfBirth = profile.dateOfBirth
                existing.registeredDate = profile.registeredDate
                existing.city = profile.city
                existing.state = profile.state
                existing.country = profile.country
                existing.largePhotoURL = profile.largePhotoURL?.absoluteString
                existing.mediumPhotoURL = profile.mediumPhotoURL?.absoluteString
                existing.page = pageNumber
                existing.cachedAt = Date()
                existing.status = currentStatus
            } else {
                context.insert(ProfileEntity(profile: profile, page: page))
            }
        }
        try context.save()
    }

    func setStatus(profileID: String, status: MatchStatus) throws {
        let context = context
        let descriptor = FetchDescriptor<ProfileEntity>(
            predicate: #Predicate { $0.id == profileID }
        )
        guard let entity = try context.fetch(descriptor).first else { return }
        entity.status = status
        try context.save()
    }

    func profile(id: String) throws -> ProfileEntity? {
        let descriptor = FetchDescriptor<ProfileEntity>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }
}
