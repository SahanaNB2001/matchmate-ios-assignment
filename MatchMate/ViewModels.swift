//
//  ViewModels.swift
//  MatchMate
//
//  Created by Sahana N B on 19/08/26.
//

import Foundation
import Combine
import SwiftData

@MainActor
final class ProfileListViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var currentPage = 0
    @Published private(set) var hasLoadedOnce = false

    let repository: ProfileRepository
    private let pageSize = 10

    init(repository: ProfileRepository) {
        self.repository = repository
    }

    func loadInitialPage() async {
        guard !hasLoadedOnce, !isLoading else { return }
        await loadNextPage()
    }

    func loadNextPage() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        let nextPage = currentPage + 1
        do {
            try await repository.fetchPage(page: nextPage, results: pageSize)
            currentPage = nextPage
            hasLoadedOnce = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func setStatus(profileID: String, status: MatchStatus) {
        do {
            try repository.setStatus(profileID: profileID, status: status)
        } catch {
            errorMessage = "Unable to save decision: \(error.localizedDescription)"
        }
    }
}

@MainActor
final class ProfileDetailViewModel: ObservableObject {
    @Published var errorMessage: String?
    private let repository: ProfileRepository

    init(repository: ProfileRepository) {
        self.repository = repository
    }

    func setStatus(profileID: String, status: MatchStatus) {
        do {
            try repository.setStatus(profileID: profileID, status: status)
        } catch {
            errorMessage = "Unable to save decision: \(error.localizedDescription)"
        }
    }
}
