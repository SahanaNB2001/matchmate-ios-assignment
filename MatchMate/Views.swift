//
//  Views.swift
//  MatchMate
//
//  Created by Sahana N B on 19/08/26.
//

import SwiftUI
import SwiftData

struct ProfileListView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: ProfileListViewModel
    private let repository: ProfileRepository

    @Query(sort: [SortDescriptor(\ProfileEntity.cachedAt)]) private var profiles: [ProfileEntity]

    init(viewModel: ProfileListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        repository = viewModel.repositoryForView
    }

    var body: some View {
        NavigationStack {
            Group {
                if profiles.isEmpty && viewModel.isLoading {
                    ProgressView("Loading profiles…")
                } else if profiles.isEmpty {
                    ContentUnavailableView(
                        "No Profiles",
                        systemImage: "person.2",
                        description: Text("Pull to retry or check your connection.")
                    )
                } else {
                    List {
                        ForEach(profiles) { entity in
                            NavigationLink {
                                ProfileDetailView(
                                    entity: entity,
                                    viewModel: ProfileDetailViewModel(repository: repository)
                                )
                            } label: {
                                ProfileCardView(entity: entity) { status in
                                    viewModel.setStatus(profileID: entity.id, status: status)
                                }
                            }
                            .buttonStyle(.plain)
                            .onAppear {
                                if entity.id == profiles.last?.id {
                                    Task { await viewModel.loadNextPage() }
                                }
                            }
                        }

                        if viewModel.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await viewModel.loadInitialPage()
                    }
                }
            }
            .navigationTitle("MatchMate")
            .task {
                await viewModel.loadInitialPage()
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
        }
    }
}

struct ProfileCardView: View {
    let entity: ProfileEntity
    let onStatusChange: (MatchStatus) -> Void

    var body: some View {
        HStack(spacing: 14) {
            AsyncImage(url: URL(string: entity.mediumPhotoURL ?? "")) { phase in
                switch phase {
                case .success(let image): image.resizable().scaledToFill()
                default: Image(systemName: "person.crop.circle.fill").resizable().scaledToFit().padding(10)
                }
            }
            .frame(width: 72, height: 72)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("\(entity.firstName) \(entity.lastName)")
                        .font(.headline)
                    Spacer()
                    StatusBadge(status: entity.status)
                }
                Text(entity.location)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if entity.status == .pending {
                    HStack {
                        Button("Accept") { onStatusChange(.accepted) }
                            .buttonStyle(.borderedProminent)
                        Button("Decline") { onStatusChange(.declined) }
                            .buttonStyle(.bordered)
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }
}

struct ProfileDetailView: View {
    let entity: ProfileEntity
    @StateObject private var viewModel: ProfileDetailViewModel

    init(entity: ProfileEntity, viewModel: ProfileDetailViewModel) {
        self.entity = entity
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                AsyncImage(url: URL(string: entity.largePhotoURL ?? "")) { phase in
                    switch phase {
                    case .success(let image): image.resizable().scaledToFill()
                    default: Image(systemName: "person.crop.circle.fill").resizable().scaledToFit().padding(40)
                    }
                }
                .frame(width: 180, height: 180)
                .clipShape(Circle())

                Text("\(entity.title) \(entity.firstName) \(entity.lastName)")
                    .font(.title.bold())

                StatusBadge(status: entity.status)

                if entity.status == .pending {
                    HStack {
                        Button("Accept") {
                            viewModel.setStatus(profileID: entity.id, status: .accepted)
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Decline") {
                            viewModel.setStatus(profileID: entity.id, status: .declined)
                        }
                        .buttonStyle(.bordered)
                    }
                }

                VStack(alignment: .leading, spacing: 14) {
                    DetailRow(title: "Email", value: entity.email)
                    DetailRow(title: "Phone", value: entity.phone)
                    DetailRow(title: "Nationality", value: entity.nationality)
                    DetailRow(title: "Gender", value: entity.gender)
                    DetailRow(title: "Location", value: "\(entity.city), \(entity.state), \(entity.country)")
                    if let dob = entity.dateOfBirth {
                        DetailRow(title: "Date of birth", value: dob.formatted(date: .abbreviated, time: .omitted))
                    }
                    if let registered = entity.registeredDate {
                        DetailRow(title: "Registered", value: registered.formatted(date: .abbreviated, time: .omitted))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.body)
        }
    }
}

struct StatusBadge: View {
    let status: MatchStatus

    var body: some View {
        Text(status.title)
            .font(.caption.bold())
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(status == .accepted ? .green.opacity(0.15) : status == .declined ? .red.opacity(0.15) : .gray.opacity(0.15))
            .foregroundStyle(status == .accepted ? .green : status == .declined ? .red : .secondary)
            .clipShape(Capsule())
    }
}

private extension ProfileListViewModel {
    var repositoryForView: ProfileRepository { repository }
}
