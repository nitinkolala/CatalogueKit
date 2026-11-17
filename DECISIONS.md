# Decisions and assumptions

Status: the features in the acceptance criteria are built, except where section 4 says a rule was dropped or simplified. Section 6 lists what is next.

## 1. Stack choice

| Layer | Choice | Why |
| --- | --- | --- |
| Client | iOS app in Swift (SwiftUI, Swift Concurrency) | Matches the `ios/` project and the `CLAUDE.md` architecture. The Simulator runs against a local backend with no extra setup. |
| Backend | Node.js with TypeScript, Express 5 | The challenge lists it as a preferred option. One language for the backend keeps the adapter and test tooling simple. |

No web client was built. The reviewer runs the iOS app in the Simulator against `http://localhost:3000`, which the challenge permits.

## 2. Architecture

```
iOS (SwiftUI)                       Backend (Node/TS)                    Product data
View -> ViewModel -> UseCase   ->   Express route -> ProductService  ->  ProductSource (interface)
           -> Repository (protocol)                 (cache, ranking,       -> FakeStoreClient
           -> RemoteDataSource / DiskCache           search, categories)      (swap for any provider)
```

- **Clients never call Fake Store directly.** The backend is the only component that knows the upstream URL (challenge constraint 2).
- **The product data source sits behind an interface.** `ProductSource` in `backend/src/domain/product.ts` is the seam. Switching to a database, a CMS or a different vendor means adding a new class, not changing the HTTP layer.
- **The backend returns its own `Product` shape.** Upstream field names (for example `image`) are mapped once, in `fakeStoreClient.ts`.
- **iOS follows the layering in `CLAUDE.md`.** Domain has no UIKit, SwiftUI or networking imports. ViewModels depend on use cases. Repositories are protocols.
- **One composition root.** `AppContainer` (iOS) wires the graph once. `AppEnvironment` decides the base URL, so no service hardcodes a host.
- **Config from the environment.** `backend/src/config/config.ts` reads `.env` values with defaults. `backend/.env.example` documents them. No secrets are committed.
- **Email is behind an interface.** `EmailSender` in `backend/src/services/enquiryService.ts` has one adapter today, `LogEmailSender`.

## 3. Assumptions where the acceptance criteria were unclear

| # | Area | Assumption | Where it lives |
| --- | --- | --- | --- |
| A1 | "Top rated" | Top rated means the highest `rating.rate`. Ties go to the higher `rating.count`, then the lower `id`, so the order is stable. | `rankTopRated` in `backend/src/domain/product.ts` |
| A2 | "I have chosen 5 products" | There is no admin UI. The admin's choice is the list in `backend/data/featured.json`, shown in that order. The backend caps it at `FEATURED_COUNT` (default 5). If the file is empty or missing, the top rated products are used. | `featured.json`, `featuredList.ts`, `productService.ts` |
| A3 | Category page | Categories come from the Fake Store `category` field. The page shows the top rated products first, then the rest of the category, in one list. | `productsInCategory` in `productService.ts`, `CategoryView.swift` |
| A4 | Search | Case-insensitive substring match on the title and the description. The category name is not searched. Results are ranked best rated first, then by rating count. The backend returns pages of 20. The app asks for the next page when the last result appears. Matching runs on the backend. | `backend/src/domain/search.ts`, `ProductSearchViewModel.swift` |
| A5 | Product page | Opening a tile shows the name, image, price, rating, stock status, description and specifications. A product that is not found shows a not-found page with a Back button. The rules that data cannot support are in section 4. | `ProductDetailView.swift` |
| A6 | Enquiry | Name, email and message are required. Phone is optional, but if entered it must be exactly 10 digits after spaces and punctuation are removed. Email uses a strict pattern. The same pattern and the same 10-digit rule run on the iOS app and the backend. | `EmailValidator`, `MobileValidator` in `Validators.swift`; `validateEnquiry` in `backend/src/domain/enquiry.ts` |
| A7 | Sales inbox | The recipient is `SALES_INBOX`. The email contains the product name, a link built from `PRODUCT_LINK_BASE`, and the customer's details. The PoC adapter logs the email to the console. No email account is needed. | `enquiryService.ts`, `logEmailSender.ts` |
| A8 | "Thank you" | After the backend accepts the enquiry, the form clears and a thank-you screen shows. A failed submit keeps everything typed and offers a retry. | `EnquiryView.swift`, `EnquiryViewModel.swift` |
| A9 | Prices and currency | Prices are shown in USD because Fake Store uses USD. Currency is a constant, not locale-driven. | `Constants.Currency` |
| A10 | Empty and error states | Featured products: a fresh saved list is shown without a network call. When the backend is unreachable, the last saved list is shown. A failed refresh while products are on screen keeps them and shows "Couldn't refresh. Showing saved products." with a retry. If nothing is saved and the request fails, a retry message appears. Categories: a failed request shows a message with a retry. A backend that returns no categories hides the section. | `FeaturedProductsRepository.swift`, `HomeViewModel.swift`, `CategoriesSectionView.swift` |
| A11 | Featured count | The app shows every product the backend sends, in order. The count is set only on the backend, so it cannot drift from the app. | `GetFeaturedProductsUseCase.swift`, `productService.ts` |
| A12 | Security | Security is out of scope for this PoC. Threats such as man-in-the-middle attacks are not in scope for now. | Not implemented |

## 4. Requirements dropped or simplified

| Requirement | Decision | Why |
| --- | --- | --- |
| Disk cache on the backend | **Dropped.** The backend uses an in-memory TTL cache only. | A single PoC process does not need persistence. `ProductService` is the boundary, so a Redis or disk cache can be added later without changing callers. |
| Disk and memory image cache, keyed by URL | **Simplified** to one `ImageLoader` with memory and disk layers. | `CLAUDE.md` requires it. Size limits and eviction are deferred. |
| Staging, Develop and Production environments | **Simplified.** `AppEnvironment` defines all three, but the staging and production hosts are placeholders. Only `develop` (`localhost:3000`) is used in the challenge. | The reviewer runs locally. No AWS infrastructure is deployed. |
| Category list pagination | **Not built.** The category page returns the full category in one response. | Fake Store categories are small. Search is paginated. |
| UI tests for the full order flow | **Deferred.** The critical path in this challenge is browsing and enquiry. The `CatalogueKitUITests` target is still the template. | Time-box. Unit and backend tests cover the critical path first. |
| Instruments performance, memory and energy checks | **Deferred.** | These need a running app on a device, and are not part of the reviewer's run path. |
| Infrastructure (AWS) | **Not included.** | Not required for the PoC. Any future infrastructure must stay AWS-compatible (challenge constraint 3). |
| Authentication | **Not included.** | Not in the acceptance criteria. Browsing and enquiries are anonymous. |
| Product metadata quality | **Not improved.** Fake Store data is used as-is. | The brief says metadata is not important yet. |

### Product page rules the data source cannot support

| Rule | What is built | Why the rest is not built |
| --- | --- | --- |
| 6. Gallery with page indicator | Swipeable gallery and pinch zoom (zoom stays until a double tap). The page indicator appears only when there is more than one image. | Fake Store gives one image per product, so the indicator never shows. |
| 7. Discount with struck-through price | Price and currency only. | No original-price or discount field exists. |
| 10. "Low stock" status | "In stock" and "Out of stock", each with an icon and text. | Fake Store has no stock quantity, so "Low stock" cannot be derived. |
| 12. Specifications list | Category, product ID and rating rows, with long values wrapping. | Fake Store has no specification data. |
| 13. Reviews with full list on demand | Average and review count in the summary line. | Fake Store has no individual reviews. |
| 27. Share | Not built. | There is no product link to share. |
| 4. Android back gesture | Not applicable. This is an iOS build. The iOS swipe-from-left-edge back gesture works. | |

Rules built with a backend change: `GET /products/:id` returns one product, and 404 for an unknown or non-numeric id.

### Enquiry rules: decisions and limits

- **Sales email.** The backend builds the email and sends it through `EmailSender`. The only adapter is `LogEmailSender`. A real provider (for example Amazon SES) is a new adapter.
- **Submit and errors.** Submit is enabled only when every field is valid: name, email and message are filled in, and a phone number, if typed, is 10 digits. Any error keeps Submit disabled. The label is always "Submit".
- **Return key.** Name and email move to the next field on Return. Phone and message use the keyboard's Done button, because a phone pad has no Return key and a message needs Return for new lines. The keyboard's Done button only appears for those two fields.
- **Back and Cancel.** Back asks to confirm before discarding typed text. The system back button is hidden. The edge swipe that leaves the page is not intercepted, so a swipe can leave without the prompt.
- **Privacy policy.** The link points to `https://example.com/privacy`, a placeholder until the client's policy URL is known.
- **Marketing consent.** An optional checkbox, unticked by default. It is saved in the email, and nothing acts on it.
- **Accessibility.** Each field's label says "required" or "optional". Errors are shown as text under the field and announced to VoiceOver.
- **Rate limiting and spam protection.** Not built. The 16 KB body limit and the validation are the only protections.

## 5. How the design supports growth beyond the PoC

- **Data source swap.** `ProductSource` on the backend and `RemoteProductDataSource` on iOS are the only places that know the wire format. Replacing Fake Store means one new adapter and a config change.
- **Email provider swap.** The `EmailSender` interface isolates the provider. Amazon SES is the expected production choice because it is AWS-compatible.
- **Look and feel.** Spacing, corner radius and colours live in `Constants` and the asset catalogue, so the design team's output can replace them without touching view logic.
- **Environments.** A real environment is one new case in `AppEnvironment` and one xcconfig entry.
- **Testing seams.** Protocols at each boundary (`ProductSource`, `ProductRepository`, `GetFeaturedProductsUseCase`, `HTTPClient`) let tests use fakes.
- **Tests.** The backend has 61 tests across 8 files (ranking, client mapping, service, search, enquiry validation, HTTP routes). The iOS app has 106 unit tests (validators, enquiry flow, search, categories, product page, featured repository, Home). `npm run typecheck` is clean.
- **Two cache policies, on purpose.** The backend caches the Fake Store list for `CACHE_TTL_SECONDS` (300). The app caches the featured list on disk for `Constants.Cache.featuredTTL` (300 seconds). They are separate policies in separate places, so the app does not depend on the server's cache.

## 6. What I would do next with another day

1. Store enquiries in a database (PostgreSQL or DynamoDB), so no enquiry is lost if the email fails.
2. Connect a real email provider (Amazon SES) behind `EmailSender`, and replace the placeholder privacy URL.
3. Add pagination to the category endpoint, and to the product list.
4. Add rate limiting on `POST /enquiries`.
5. Add an XCUITest for the critical path (browse, open a product, submit an enquiry) and a `docker compose up` setup for the backend.
6. Check landscape, VoiceOver and larger text sizes on a physical device. The Simulator covered portrait and dark mode only.
7. Add CI that runs the backend tests and the iOS unit tests on each pull request.
8. Show a notice when the app opens offline with a saved list. Today the saved list is shown without a notice when it is still within its 5-minute window, and the notice appears only after a refresh fails.

## 7. Time spent

Actual time: **[fill in]**

| Phase | Time |
| --- | --- |
| Planning | [fill in] |
| Building | [fill in] |
| Testing | [fill in] |
| Reviewing | [fill in] |
