//
//  MatchMateApp.swift
//  MatchMate
//
//  Created by Sahana N B on 18/08/26.
//

import SwiftUI
import SwiftData

@main
struct MatchMateApp: App {
    let container: ModelContainer
    let repository: ProfileRepository

    init() {
        do {
            let schema = Schema([ProfileEntity.self])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [configuration])
            repository = ProfileRepository(
                api: RandomUserAPI(),
                modelContainer: container
            )
        } catch {
            fatalError("Unable to create SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ProfileListView(viewModel: ProfileListViewModel(repository: repository))
        }
        .modelContainer(container)
    }
}
