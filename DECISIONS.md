# Decisions and assumptions

Status: this document is written alongside the build. Sections marked **Built** describe code that exists in the repo today. Sections marked **Planned** describe work that is not yet implemented.

## 1. Stack choice

| Layer | Choice | Why |
| --- | --- | --- |
| Client | iOS app in Swift (SwiftUI, Swift Concurrency) | Matches the existing `ios/` project and the `CLAUDE.md` architecture. Simulator runs against a local backend are straightforward. |
| Backend | Node.js with TypeScript, Express 5 | The challenge lists it as a preferred option. One language for the backend keeps the adapter and test tooling simple. |

I did not build a web client. The reviewer runs the iOS app in the Simulator against `http://localhost:3000`, which the challenge permits.

## 2. Architecture

```
iOS (SwiftUI)                      Backend (Node/TS)                    Product data
View -> ViewModel -> UseCase   ->  Express route -> ProductService  ->  ProductSource (interface)
           -> Repository (protocol)   (cache, ranking)                      -> FakeStoreClient
           -> RemoteDataSource / DiskCache                                 (swap for any provider)
```

- **Clients never call Fake Store directly.** The backend is the only component that knows the upstream URL (challenge constraint 2).
- **The product data source sits behind an interface.** `ProductSource` in `backend/src/domain/product.ts` is the seam. Switching to a database, a CMS or a different vendor means adding a new class, not changing the HTTP layer.
- **The backend returns its own `Product` shape.** The upstream field names (for example `image`) are mapped once, in `fakeStoreClient.ts`. The API contract does not leak upstream changes to the client.
- **iOS follows the layering in `CLAUDE.md`.** Domain has no UIKit, SwiftUI or networking imports. ViewModels depend on use cases. The repository is a protocol, so the PoC data source can be replaced without touching the UI.
- **One composition root.** `AppContainer` (iOS) wires the graph once. Environment selection (`AppEnvironment`) decides the base URL, so there are no hardcoded hosts in services.
- **Config from the environment.** `backend/src/config/config.ts` reads `.env` values with defaults and validation. `.env.example` documents them. No secrets are committed.

## 3. Assumptions where the acceptance criteria were unclear

| # | Area | Assumption | Where it lives |
| --- | --- | --- | --- |
| A1 | "Top rated" | Top rated means the highest `rating.rate`. Ties go to the higher `rating.count`, then the lower `id` so the order is stable. | `rankTopRated` in `product.ts` |
| A2 | "I have chosen 5 products" | The entrepreneur's choice is approximated by the top 5 by rating. There is no admin UI to pin products. The count is configurable with `FEATURED_COUNT`. | `config.ts`, `productService.ts` |
| A3 | Category page | Categories come from the Fake Store `category` field. The category page shows the top-rated products first, then the rest of that category. Pagination is planned, not built. | Planned |
| A4 | Search | Search is a case-insensitive substring match on title and description. An empty term shows the full list. Search runs on the backend, so results come from the same data source. | Planned |
| A5 | Product page | Opening a tile shows title, image, price, rating, category and description. A product that is not found shows an error state. | Planned |
| A6 | Enquiry | The form captures name, email, phone and a message. Email is required and validated with a strict pattern. Phone is required and must be exactly 10 digits after stripping spaces and punctuation, per the `MobileValidator` rule in `CLAUDE.md`. This assumes an Australian-style number, which fits the retailer context. | Planned |
| A7 | Sales inbox | The recipient address is configured with an env variable. Email is sent through an `EmailSender` interface. The PoC adapter writes to the log and to a local SMTP catcher. A real provider can be added later. No paid email account is needed to run the solution. | Planned |
| A8 | "Thank you" | After the backend accepts the enquiry, the client shows a thank-you screen. A failed send shows an error and keeps the form contents. | Planned |
| A9 | Prices and currency | Prices are shown in USD because Fake Store uses USD. Currency is a constant, not a locale-driven value. | `Constants.Currency` |
| A10 | Empty and error states | A failed backend call shows a retry message. If the backend is down, the iOS app falls back to the last saved featured list, even if it is stale. | `FeaturedProductsRepository.swift` |

## 4. Requirements dropped or simplified

| Requirement | Decision | Why |
| --- | --- | --- |
| Disk cache on the backend | **Dropped.** The backend uses an in-memory TTL cache only. | A single PoC process does not need persistence. The `ProductService` boundary means a Redis or disk cache can be added later without changing callers. |
| Disk and memory image cache, keyed by URL | **Simplified** to a single `ImageLoader` with memory and disk layers. | `CLAUDE.md` requires it. Full image-cache tuning (size limits, eviction) is deferred. |
| Staging, Develop and Production environments | **Simplified.** `AppEnvironment` defines all three, but the staging and production hosts are placeholders. Only `develop` (`localhost:3000`) is used in the challenge. | The reviewer runs locally. No AWS infrastructure is deployed, so there is nothing real to point at. |
| UI tests for the full order flow | **Deferred.** The challenge's critical path is catalogue browsing and enquiry, not orders. The `CatalogueKitUITests` target is a template placeholder for now. | Time-box. Unit and backend integration tests cover the critical path first. |
| Instruments performance, memory and energy checks | **Deferred.** | These need a running app on a device or Simulator and are not part of the reviewer's run path. |
| Infrastructure (AWS) | **Not included.** | Not required for the PoC. Any future infrastructure must stay AWS-compatible (challenge constraint 3). |
| Authentication | **Not included.** | Not in the acceptance criteria. Enquiries are anonymous. |
| Product metadata quality | **Not improved.** Fake Store data is used as-is. | The brief says metadata is not important yet. |

## 5. How the design supports growth beyond the PoC

- **Data source swap.** `ProductSource` on the backend and `RemoteProductDataSource` on iOS are the only places that know the wire format. Replacing Fake Store means one new adapter and a config change.
- **Email provider swap.** The `EmailSender` interface isolates the provider. Amazon SES is the expected production choice because it is AWS-compatible.
- **Look and feel.** Visual values (spacing, corner radius, colours) live in `Constants` and the asset catalogue. The design team's output can replace them without touching views' logic.
- **Environments.** Adding a real environment means one new case in `AppEnvironment` and one xcconfig entry.
- **Testing seams.** Protocols at each boundary (`ProductSource`, `ProductRepository`, `GetFeaturedProductsUseCase`, `HTTPClient`) let tests use fakes. The iOS unit tests (16 cases across the repository, use case, view model and DTO mapping) pass on the iPhone 17 Pro Simulator. The backend tests (24 cases across 5 files: ranking, client mapping, service, HTTP routes) pass under Node 22.23.5, and `tsc --noEmit` is clean.
- **Known gaps to fix before growth.** Featured count and cache TTL are duplicated between the backend config and `Constants.swift`. The iOS value should come from the backend or from config, so the two cannot drift. This is on the next-steps list.

## 6. What I would do next with another day

1. Finish the core flows: category page, search, product detail, and the enquiry form with its `EmailSender` and validators.
2. Add a server-side enquiry endpoint with validation, rate limiting, and a unit test for each rule.
3. Remove duplicated config: serve the featured count and cache TTL from the backend response, or from one shared config file.
4. Add pagination to the product list and category endpoints, rather than returning the whole list.
5. Add an end-to-end test for the critical path: browse, open a product, submit an enquiry.
6. Add a `docker compose up` setup for the backend and a local SMTP catcher, so the reviewer needs one command.
7. Add CI to run the backend tests and the iOS unit tests on each PR.
8. Add a persistence layer for enquiries (PostgreSQL or DynamoDB) so no enquiry is lost if the email fails.
9. Review the staged `.DS_Store` files and remove them from the commit. `CLAUDE.md` says they should not be committed.

## 7. Time spent

Actual time: **[fill in]**

| Phase | Time |
| --- | --- |
| Planning | [fill in] |
| Building | [fill in] |
| Testing | [fill in] |
| Reviewing | [fill in] |
