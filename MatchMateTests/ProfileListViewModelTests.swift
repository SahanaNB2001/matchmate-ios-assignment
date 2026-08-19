import XCTest
import SwiftData
@testable import MatchMate

final class ProfileListViewModelTests: XCTestCase {
    @MainActor
    func testLoadNextPageIncrementsPage() async throws {
        let container = try ModelContainer(
            for: ProfileEntity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let api = MockProfileAPI()
        let repository = ProfileRepository(api: api, modelContainer: container)
        let vm = ProfileListViewModel(repository: repository)

        await vm.loadNextPage()

        XCTAssertEqual(vm.currentPage, 1)
        XCTAssertTrue(vm.hasLoadedOnce)
    }

    @MainActor
    func testFailedRequestExposesError() async throws {
        let container = try ModelContainer(
            for: ProfileEntity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let api = MockProfileAPI(shouldFail: true)
        let repository = ProfileRepository(api: api, modelContainer: container)
        let vm = ProfileListViewModel(repository: repository)

        await vm.loadNextPage()

        XCTAssertNotNil(vm.errorMessage)
        XCTAssertEqual(vm.currentPage, 0)
    }
}

struct MockProfileAPI: ProfileAPI {
    var shouldFail = false
    init(shouldFail: Bool = false) { self.shouldFail = shouldFail }

    func fetchProfiles(page: Int, results: Int) async throws -> [Profile] {
        if shouldFail { throw APIError.invalidResponse }
        return (0..<results).map { index in
            Profile(
                id: "\(page)-\(index)", title: "Mr", firstName: "Test", lastName: "User \(index)",
                email: "test@example.com", phone: "123", nationality: "IN", gender: "male",
                dateOfBirth: nil, registeredDate: nil, city: "Bengaluru", state: "Karnataka", country: "India",
                largePhotoURL: nil, mediumPhotoURL: nil
            )
        }
    }
}
