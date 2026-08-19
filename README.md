# MatchMate — iOS Coding Assignment

A small matrimonial-style iOS application built with SwiftUI, SwiftData, async/await, and MVVM + Repository architecture.

The application fetches profiles from the Random User API, displays them as match cards, allows users to open a full profile, and supports Accept/Decline actions from both the list and detail screens.

## Features

* SwiftUI match profile list
* Profile detail screen
* Accept / Decline actions
* Status synchronization between list and detail
* Persistent local storage using SwiftData
* Offline cached profiles
* Accept / Decline while offline
* Random User API integration
* Real pagination
* Stable profile IDs using `login.uuid`
* Async/await networking using URLSession
* API and persistence error handling
* ViewModel unit tests
* Basic UI test

## Requirements

* Xcode 16+
* iOS 17+
* Swift 5.9+
* SwiftUI
* SwiftData

## Getting Started

1. Clone the repository.

```bash
git clone <YOUR_GITHUB_REPOSITORY_URL>
```

2. Open:

```text
MatchMate.xcodeproj
```

3. Select the `MatchMate` scheme.

4. Select an iOS 17+ simulator.

5. Build and run using `⌘R`.

No API key or external configuration is required.

## Architecture

The project follows MVVM with a Repository layer:

```text
SwiftUI Views
      ↓
ViewModels
      ↓
ProfileRepository
      ↓
 ┌───────────────┐
 │               │
RandomUserAPI   SwiftData
```

### Views

SwiftUI views are responsible primarily for displaying state and forwarding user actions.

### ViewModels

ViewModels manage screen state, pagination state, loading state, and errors.

### Repository

`ProfileRepository` provides a single boundary between the ViewModels and data sources.

It coordinates:

* Remote API requests
* SwiftData persistence
* Profile status updates
* Cached data

### API

`RandomUserAPI` uses `URLSession` and Swift concurrency.

The endpoint uses:

```text
https://randomuser.me/api/?page=<page>&results=10&seed=matchmate
```

The `seed=matchmate` parameter keeps the returned dataset stable for review.

`login.uuid` is used as the stable profile identifier.

## Why SwiftData?

SwiftData was selected instead of Core Data because this is a new SwiftUI application and SwiftData provides a modern, concise persistence API that integrates naturally with SwiftUI.

SwiftData is used as the local source of truth for cached profiles and their Accept/Decline status.

## Pagination

The application starts with page 1.

When the user approaches the end of the list, the ViewModel requests the next page.

```text
Page 1
  ↓
Page 2
  ↓
Page 3
  ↓
...
```

The repository persists fetched profiles locally while preserving an existing profile's status.

This is important because a profile may already have been Accepted or Declined when its data is refreshed.

## Status Synchronization

Each profile is identified by its stable `login.uuid`.

The Accept/Decline status is stored with the profile in SwiftData.

```text
Profile ID
    ↓
SwiftData
    ↓
Status
    ↓
List + Detail
```

Therefore, the list and detail screens use the same persisted status.

For example:

```text
List
  ↓
Accept
  ↓
SwiftData: accepted
  ↓
Detail
  ↓
Accepted
```

The same also works in the opposite direction:

```text
Detail
  ↓
Decline
  ↓
SwiftData: declined
  ↓
Back to List
  ↓
Declined
```

This avoids maintaining separate status values in the list and detail screens.

## Offline Behavior

Previously fetched profiles are stored in SwiftData.

When the device is offline:

* Cached profiles remain available.
* Accept/Decline actions continue to work.
* Status changes are persisted locally.

When connectivity is restored, subsequent API requests can refresh the cached profile data.

## Error Handling

The application handles errors at the API/repository and ViewModel levels.

Examples include:

* Invalid HTTP response
* HTTP server errors
* Empty API responses
* Network failures
* SwiftData persistence failures

The UI exposes user-readable error messages instead of silently failing.

## Testing

The project contains:

### Unit Tests

`MatchMateTests/ProfileListViewModelTests.swift`

The tests cover ViewModel behavior including:

* Pagination state
* Successful loading
* API failure handling

The API is abstracted behind `ProfileAPI`, allowing a mock API to be injected into the repository during testing.

### UI Tests

`MatchMateUITests/MatchMateUITests.swift`

A basic UI test verifies that the application can launch successfully.

Run all tests using:

```text
⌘U
```

or:

```text
Product → Test
```

## Project Structure

```text
MatchMate/
├── MatchMate/
│   ├── MatchMateApp.swift
│   ├── Models.swift
│   ├── API.swift
│   ├── Repository.swift
│   ├── ViewModels.swift
│   └── Views.swift
│
├── MatchMateTests/
│   └── ProfileListViewModelTests.swift
│
├── MatchMateUITests/
│   └── MatchMateUITests.swift
│
├── MatchMate.xcodeproj/
├── README.md
└── .gitignore
```

## Known Gaps

* Image caching is currently handled by SwiftUI's `AsyncImage`; a dedicated image cache could be introduced for more control in a production application.
* Offline API synchronization is intentionally kept lightweight for the scope of this assignment.
* The UI is intentionally simple and focuses on the requested user flow rather than pixel-perfect visual design.
* UI test coverage can be expanded to cover Accept/Decline and navigation flows.

## Assignment Checklist

* [x] SwiftUI match-card list
* [x] Real pagination
* [x] List → profile detail navigation
* [x] Accept / Decline from list
* [x] Accept / Decline from detail
* [x] Persistent status
* [x] Status synchronization between list and detail
* [x] Offline cached profiles
* [x] Offline Accept / Decline
* [x] SwiftData persistence
* [x] MVVM + Repository
* [x] URLSession + async/await
* [x] API error handling
* [x] ViewModel unit tests
* [x] Basic UI test

## Time Spent

Approximately: 3 hours

## Author

Sahana N B
