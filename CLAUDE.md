# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Current state

The repo has only `README.md` and an Xcode/Swift `.gitignore`. No Xcode project, Swift package, or tests exist yet. Check for `.xcodeproj`, `.xcworkspace`, or `Package.swift` before assuming a build exists, and don't invent build, test, or lint commands.

## Stack

- iOS app in Swift, using Swift Concurrency and SwiftUI/UIKit as the project decides.
- Node.js applies only if a backend is added to this repo. Check `package.json` for real scripts and the lockfile's package manager before running anything.

## Architecture: MVVM + Clean

- Layers: Presentation (View, ViewModel), Domain (Entities, UseCases, Repository protocols), Data (Repository implementations, remote API client, local cache).
- Dependencies point inward only. Domain imports nothing from UIKit, SwiftUI, or Data.
- ViewModels call UseCases, never networking or cache directly. Mark them `@MainActor`.
- Inject dependencies through initializers. Wire them in one composition root.

## SOLID

- Single responsibility per type. Split a ViewModel when it grows past one concern.
- Depend on protocols at layer boundaries (Repository, Service, Validator). Don't pass concrete Data types into Domain or Presentation.
- Extend behavior by adding types, not by adding flags to existing ones.

## Caching

- Data: cache responses behind the Repository, in memory and on disk, with an explicit expiry policy. Repository decides cache-first vs network-first.
- Images: use a shared image cache (memory + disk) keyed by URL. Don't load raw images in Views.
- Invalidate caches on logout and on environment switch.

## No hardcoding

- No magic numbers or string literals in logic or views. Put them in named constants, enums, or config.
- User-facing text goes in `Localizable.strings` / String Catalog keys.
- Endpoints, timeouts, cache sizes, and limits come from config, not inline.

## Validation

- Email: validate with a single `EmailValidator` in Domain. Use a strict pattern, not `contains("@")`.
- Mobile: exactly 10 digits, digits only, after stripping the formatting the user typed. One `MobileValidator` in Domain.
- Both validators get unit tests covering valid, invalid, and boundary inputs (9 and 11 digits, leading/trailing spaces).

## Environments

- Three endpoints: Staging, Develop, Production. Select one per build configuration (Debug/Staging/Release) via xcconfig or build settings, and expose it through a single `AppEnvironment` config.
- Never hardcode a base URL in a service. Don't commit credentials for any environment.

## Testing

- Unit tests for UseCases, Repositories (with protocol fakes), ViewModels, and validators.
- Memory: run Instruments Leaks and Allocations on main flows. Fix retain cycles from ViewModel closures.
- Performance: XCTest `measure` blocks for parsing, caching, and list rendering. Keep a baseline.
- Battery: check Instruments Energy Log on network-heavy and image-heavy screens. Batch requests and avoid polling.
- Thermal: observe `ProcessInfo.thermalState` on long sessions. Reduce work (image sizes, animations) when the state is `.serious` or `.critical`.
- Run tests with `xcodebuild test` on a simulator once the scheme exists.

## Repo hygiene

- Don't commit `xcuserdata/`, `DerivedData/`, or build output.
- Leave signing, provisioning, and team IDs alone unless asked.
