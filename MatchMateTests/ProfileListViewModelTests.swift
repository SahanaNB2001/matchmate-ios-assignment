import XCTest
import SwiftData
@testable import MatchMate

@MainActor
final class ProfileListViewModelTests: XCTestCase {

    // MARK: - Helper

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: ProfileEntity.self,
            configurations: ModelConfiguration(
                isStoredInMemoryOnly: true
            )
        )
    }

    // MARK: - Existing Tests

    func testLoadNextPageIncrementsPage() async throws {

        let container = try makeContainer()

        let api = MockProfileAPI()

        let repository = ProfileRepository(
            api: api,
            modelContainer: container
        )

        let vm = ProfileListViewModel(
            repository: repository
        )

        await vm.loadNextPage()

        XCTAssertEqual(vm.currentPage, 1)
        XCTAssertTrue(vm.hasLoadedOnce)
        XCTAssertFalse(vm.isLoading)
    }

    func testFailedRequestExposesError() async throws {

        let container = try makeContainer()

        let api = MockProfileAPI(
            shouldFail: true
        )

        let repository = ProfileRepository(
            api: api,
            modelContainer: container
        )

        let vm = ProfileListViewModel(
            repository: repository
        )

        await vm.loadNextPage()

        XCTAssertNotNil(vm.errorMessage)
        XCTAssertEqual(vm.currentPage, 0)
        XCTAssertFalse(vm.hasLoadedOnce)
        XCTAssertFalse(vm.isLoading)
    }

    // MARK: - Pagination

    func testSecondPageLoadsCorrectly() async throws {
        let container = try makeContainer()
        let api = MockProfileAPI()

        let repository = ProfileRepository(
            api: api,
            modelContainer: container
        )

        let vm = ProfileListViewModel(
            repository: repository
        )

        await vm.loadNextPage()
        XCTAssertEqual(vm.currentPage, 1)

        await vm.loadNextPage()
        XCTAssertEqual(vm.currentPage, 2)
        
        XCTAssertTrue(vm.hasLoadedOnce)
    }
    // MARK: - Accept

    func testAcceptProfile() async throws {

        let container = try makeContainer()

        let api = MockProfileAPI()

        let repository = ProfileRepository(
            api: api,
            modelContainer: container
        )

        let vm = ProfileListViewModel(
            repository: repository
        )

        // Load profiles into SwiftData
        await vm.loadNextPage()

        let context = ModelContext(container)

        let descriptor = FetchDescriptor<ProfileEntity>()

        let profiles = try context.fetch(descriptor)

        guard let profile = profiles.first else {
            XCTFail("Expected a profile to exist")
            return
        }

        // Accept the profile
        vm.setStatus(
            profileID: profile.id,
            status: .accepted
        )

        // Fetch it again
        let updatedProfiles = try context.fetch(descriptor)

        guard let updatedProfile = updatedProfiles.first(
            where: { $0.id == profile.id }
        ) else {
            XCTFail("Expected profile to exist")
            return
        }

        XCTAssertEqual(
            updatedProfile.status,
            .accepted
        )
    }

    // MARK: - Decline

    func testDeclineProfile() async throws {

        let container = try makeContainer()

        let api = MockProfileAPI()

        let repository = ProfileRepository(
            api: api,
            modelContainer: container
        )

        let vm = ProfileListViewModel(
            repository: repository
        )

        await vm.loadNextPage()

        let context = ModelContext(container)

        let descriptor = FetchDescriptor<ProfileEntity>()

        let profiles = try context.fetch(descriptor)

        guard let profile = profiles.first else {
            XCTFail("Expected a profile to exist")
            return
        }

        // Decline the profile
        vm.setStatus(
            profileID: profile.id,
            status: .declined
        )

        let updatedProfiles = try context.fetch(descriptor)

        guard let updatedProfile = updatedProfiles.first(
            where: { $0.id == profile.id }
        ) else {
            XCTFail("Expected profile to exist")
            return
        }

        XCTAssertEqual(
            updatedProfile.status,
            .declined
        )
    }
    
    func testPendingProfile() async throws {

        let container = try makeContainer()

        let api = MockProfileAPI()

        let repository = ProfileRepository(
            api: api,
            modelContainer: container
        )

        let vm = ProfileListViewModel(
            repository: repository
        )

        await vm.loadNextPage()

        let context = ModelContext(container)

        let descriptor = FetchDescriptor<ProfileEntity>()

        let profiles = try context.fetch(descriptor)

        guard let profile = profiles.first else {
            XCTFail("Expected a profile")
            return
        }

        //  Pending profile
        vm.setStatus(
            profileID: profile.id,
            status: .pending
        )

        let updatedProfiles = try context.fetch(descriptor)

        guard let updatedProfile = updatedProfiles.first(
            where: { $0.id == profile.id }
        ) else {
            XCTFail("Expected profile")
            return
        }

        XCTAssertEqual(
            updatedProfile.status,
            .pending
        )
    }

    // MARK: - Existing Status Preservation

    func testExistingStatusIsNotOverwrittenWhenProfileIsRefreshed() async throws {

        let container = try makeContainer()

        let api = MockProfileAPI()

        let repository = ProfileRepository(
            api: api,
            modelContainer: container
        )

        let vm = ProfileListViewModel(
            repository: repository
        )

        // First API call.
        await vm.loadNextPage()

        let context = ModelContext(container)

        let descriptor = FetchDescriptor<ProfileEntity>()

        guard let profile = try context.fetch(descriptor).first else {
            XCTFail("Expected a profile")
            return
        }

        // User accepts the profile.
        vm.setStatus(
            profileID: profile.id,
            status: .accepted
        )

        // Verify it is accepted.
        let acceptedProfiles = try context.fetch(descriptor)

        guard let acceptedProfile = acceptedProfiles.first(
            where: { $0.id == profile.id }
        ) else {
            XCTFail("Expected profile to exist")
            return
        }

        XCTAssertEqual(
            acceptedProfile.status,
            .accepted
        )

        // Fetch the SAME API page again.
        //
        // The API returns the profile again with its default
        // status, but the repository should preserve "accepted".
        try await repository.fetchPage(
            page: 1,
            results: 10
        )

        // Read the profile again.
        let refreshedProfiles = try context.fetch(descriptor)

        guard let refreshedProfile = refreshedProfiles.first(
            where: { $0.id == profile.id }
        ) else {
            XCTFail("Expected profile to exist after refresh")
            return
        }

        XCTAssertEqual(
            refreshedProfile.status,
            .accepted,
            "Refreshing API data should not overwrite the user's existing decision"
        )
    }

    // MARK: - Declined Status Preservation

    func testExistingDeclinedStatusIsNotOverwrittenWhenProfileIsRefreshed() async throws {

        let container = try makeContainer()

        let api = MockProfileAPI()

        let repository = ProfileRepository(
            api: api,
            modelContainer: container
        )

        let vm = ProfileListViewModel(
            repository: repository
        )

        await vm.loadNextPage()

        let context = ModelContext(container)

        let descriptor = FetchDescriptor<ProfileEntity>()

        guard let profile = try context.fetch(descriptor).first else {
            XCTFail("Expected a profile")
            return
        }

        vm.setStatus(
            profileID: profile.id,
            status: .declined
        )

        // Refresh the same page.
        try await repository.fetchPage(
            page: 1,
            results: 10
        )

        let refreshedProfiles = try context.fetch(descriptor)

        guard let refreshedProfile = refreshedProfiles.first(
            where: { $0.id == profile.id }
        ) else {
            XCTFail("Expected profile to exist after refresh")
            return
        }

        XCTAssertEqual(
            refreshedProfile.status,
            .declined,
            "Refreshing API data should not overwrite the user's decline decision"
        )
    }

    // MARK: - Initial Page

    func testLoadInitialPageOnlyLoadsOnce() async throws {

        let container = try makeContainer()

        let api = MockProfileAPI()

        let repository = ProfileRepository(
            api: api,
            modelContainer: container
        )

        let vm = ProfileListViewModel(
            repository: repository
        )

        await vm.loadInitialPage()

        XCTAssertEqual(
            vm.currentPage,
            1
        )

        XCTAssertTrue(
            vm.hasLoadedOnce
        )

        // Calling loadInitialPage again should do nothing.
        await vm.loadInitialPage()

        XCTAssertEqual(
            vm.currentPage,
            1
        )
    }
}


// MARK: - Mock API

actor MockProfileAPI: ProfileAPI {

    var shouldFail = false

    init(
        shouldFail: Bool = false
    ) {
        self.shouldFail = shouldFail
    }

    func fetchProfiles(
        page: Int,
        results: Int
    ) async throws -> [Profile] {

        if shouldFail {
            throw APIError.invalidResponse
        }

        return (0..<results).map { index in

            Profile(
                id: "\(page)-\(index)",
                title: "Mr",
                firstName: "Test",
                lastName: "User \(index)",
                email: "test@example.com",
                phone: "123",
                nationality: "IN",
                gender: "male",
                dateOfBirth: nil,
                registeredDate: nil,
                city: "Bengaluru",
                state: "Karnataka",
                country: "India",
                largePhotoURL: nil,
                mediumPhotoURL: nil
            )
        }
    }
}
