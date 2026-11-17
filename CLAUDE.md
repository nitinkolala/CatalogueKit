# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Current state

The repo holds a working proof of concept: an iOS app in `ios/CatalogueKit/` and a Node.js backend in `backend/`. See `README.md` for setup and `DECISIONS.md` for the assumptions behind it.

Commands (run from the folder shown):

- Backend (`backend/`, Node 20+): `npm install`, `npm run dev` (port 3000), `npm test` (Vitest), `npm run typecheck`.
- iOS (`ios/CatalogueKit/`): open `CatalogueKit.xcodeproj`, scheme `CatalogueKit`, run on an iPhone Simulator. Unit tests: `xcodebuild test -project CatalogueKit.xcodeproj -scheme CatalogueKit -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:CatalogueKitTests`.

Check for these before assuming other build tools exist. The backend uses `package.json` and `package-lock.json`, so use npm.

## Stack

- iOS app in Swift, using Swift Concurrency and SwiftUI.
- Backend in TypeScript on Express 5, with the product data source behind the `ProductSource` interface. The client never calls the upstream product API directly.

## Git

- Default branch `main`. Work on feature branches and do not merge into `main` without asking.
- Remote `origin` is `github.com/nitinkolala/CatalogueKit`.

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
- Backend tests cover search, categories, product lookup and enquiry validation through the HTTP routes (`backend/test`).
- UI tests: the `CatalogueKitUITests` target is still the template. The order flow is out of scope for this PoC (DECISIONS.md, section 4). When UI tests are added, cover browse, product, and enquiry.
- Memory: run Instruments Leaks and Allocations on main flows. Fix retain cycles from ViewModel closures.
- Performance: XCTest `measure` blocks for parsing, caching, and list rendering. Keep a baseline.
- Battery: check Instruments Energy Log on network-heavy and image-heavy screens. Batch requests and avoid polling.
- Thermal: observe `ProcessInfo.thermalState` on long sessions. Reduce work (image sizes, animations) when the state is `.serious` or `.critical`.
- Run iOS unit tests with `xcodebuild test` on the iPhone 17 Pro Simulator (commands in Current state). Run backend tests with `npm test`.

## Repo hygiene

- Don't commit `xcuserdata/`, `DerivedData/`, or build output.
- Leave signing, provisioning, and team IDs alone unless asked.
