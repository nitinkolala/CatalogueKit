# Static data and hardcoded values

Every URL, port, limit, timeout, storage key, file name and placeholder that is fixed in the code, with its location. Items marked **config** can already be changed without editing code. Items marked **code** are fixed in source and would need a change to move into config.

Paths are relative to the repository root. Line numbers are approximate and may drift as the code changes.

## 1. URLs and ports

| Value | Where | Status | Notes |
| --- | --- | --- | --- |
| `https://fakestoreapi.com` | `backend/src/config/config.ts` (DEFAULTS) | **config** `FAKESTORE_BASE_URL` | Product data source |
| `http://localhost:3000` | `backend/src/config/config.ts` (DEFAULTS) | **config** `PORT` | Backend port |
| `http://localhost:3000/products` | `backend/src/config/config.ts` (DEFAULTS) | **config** `PRODUCT_LINK_BASE` | Base of the product link in enquiry emails |
| `http://localhost:3000` | `ios/.../Core/AppEnvironment.swift` (`develop`) | **config** `API_BASE_URL` override | Debug builds use this |
| `https://staging.api.example.com` | `ios/.../Core/AppEnvironment.swift` (`staging`) | **code** placeholder | Replace with the real staging host |
| `https://api.example.com` | `ios/.../Core/AppEnvironment.swift` (`production`) | **code** placeholder | Replace with the real production host |
| `https://example.com/privacy` | `ios/.../Core/Constants.swift` (`Enquiry.privacyPolicyURL`) | **code** placeholder | Replace with the client's privacy policy URL |
| `http://localhost:3000` in the startup log | `backend/src/server.ts` | **code** | Log text only. It does not follow `PORT` |
| `https://fakestoreapi.com/products` in a comment | `backend/src/data/fakeStoreClient.ts` | comment only | Documentation |
| `/products`, `/products/featured`, `/products/categories`, `/products/search`, `/enquiries` | `backend/src/http/app.ts` (`ROUTES`) | **code** | The API contract. The iOS app repeats these paths (see section 5) |
| `products/featured`, `products/categories`, `products/search`, `enquiries` | `ios/.../Data/RemoteProductDataSource.swift` (`Path`), `RemoteEnquiryRepository.swift` | **code** | The iOS side of the same paths. These must match the backend |

## 2. Backend configuration defaults

All of these are read from environment variables. The values below are the defaults, and they are documented in `backend/.env.example`.

| Variable | Default | Where | Meaning |
| --- | --- | --- | --- |
| `PORT` | `3000` | `config.ts` | Listen port |
| `FAKESTORE_BASE_URL` | `https://fakestoreapi.com` | `config.ts` | Product data source |
| `FEATURED_COUNT` | `5` | `config.ts` | Maximum featured products |
| `CACHE_TTL_SECONDS` | `300` | `config.ts` | Backend product-list cache (converted to ms with `MS_PER_SECOND = 1000`) |
| `UPSTREAM_TIMEOUT_MS` | `5000` | `config.ts` | Timeout for Fake Store calls |
| `FEATURED_LIST_PATH` | `data/featured.json` | `config.ts` | Admin's featured list |
| `SALES_INBOX` | `sales@example.com` | `config.ts` | Enquiry recipient. The default is a placeholder |
| `PRODUCT_LINK_BASE` | `http://localhost:3000/products` | `config.ts` | Product link in emails |

## 3. Backend limits and rules (code)

| Value | Where | Meaning |
| --- | --- | --- |
| Search query: 2 to 100 characters | `backend/src/domain/search.ts` (`SEARCH_LIMITS.minLength`, `maxLength`) | Query length |
| Search page size 20, maximum 50 | `search.ts` (`defaultLimit`, `maxLimit`) | Results per page |
| Enquiry name up to 100 characters | `backend/src/domain/enquiry.ts` (`ENQUIRY_LIMITS.nameMaxLength`) | Name length |
| Enquiry message up to 1000 characters | `enquiry.ts` (`messageMaxLength`) | Message length |
| Phone: 10 digits | `enquiry.ts` (`phoneDigits`) | Phone length after formatting is removed |
| Request body limit 16 KB | `backend/src/http/app.ts` (`express.json({ limit: '16kb' })`) | Maximum request size |
| Email pattern | `enquiry.ts` (`EMAIL_PATTERN`) | Strict email format |
| Phone formatting characters `space - ( ) .` | `enquiry.ts` (`normalizePhone`) | Removed before the length check |
| Ties in ranking: rating, then rating count, then lower id | `backend/src/domain/product.ts` (`rankTopRated`) | Ordering |
| Featured list ignores items that no longer exist | `backend/src/services/productService.ts` | Behaviour |

## 4. Backend text (code)

User-facing messages returned by the API. They are English only and are not localized.

| Message | Where |
| --- | --- |
| "Category not found", "Product not found", "Route not found", "Something went wrong" | `backend/src/http/app.ts` |
| "Search needs 2 to 100 characters" | `app.ts` (uses the limits from section 3) |
| "Check the highlighted fields" | `app.ts` |
| "Request body is not valid JSON", "Request body is too large" | `app.ts` |
| "Product data is temporarily unavailable" | `app.ts` |
| "Enter a valid email address", "Enter your name (up to 100 characters)", "Enter a message (up to 1000 characters)", "Product is missing" | `enquiry.ts` |
| Enquiry email subject `Enquiry about <product title>`, and the body fields | `backend/src/services/enquiryService.ts` |
| `[email] to=… subject=…` console line | `backend/src/infra/logEmailSender.ts` |

## 5. iOS network and API (code)

| Value | Where | Meaning |
| --- | --- | --- |
| Request timeout 10 s | `ios/.../Core/Constants.swift` (`Network.requestTimeout`) | Every HTTP request |
| Success status range 200 to 299 | `Constants.swift` (`Network.successStatusRange`) | Treated as success |
| `Content-Type: application/json` | `ios/.../Data/HTTPClient.swift` | Header on POST |
| Paths listed in section 1 | `RemoteProductDataSource.swift`, `RemoteEnquiryRepository.swift` | Must match the backend |
| Status 404 handled as "not found" | `ios/.../Data/RemoteProductDetailRepository.swift` | Product page |

## 6. iOS caching and storage (code)

| Value | Where | Meaning |
| --- | --- | --- |
| Featured list cache: 300 s | `Constants.swift` (`Cache.featuredTTL`) | Fresh cached list is shown without a network call. Separate from the backend's own 300 s cache |
| Cache folder `CatalogueKitCache` | `Constants.swift` (`Cache.directoryName`) | Under the app's Caches folder |
| Cache file `featured-products.json` | `Constants.swift` (`Cache.productsFileName`) | Saved featured list |
| Image cache subfolder `images` | `ios/.../Data/ImageLoader.swift` | Disk image cache |
| Recent searches key `catalogue.recentSearches` | `Constants.swift` (`Search.recentSearchesKey`) | UserDefaults key |
| Recent searches icon `clock` | `Constants.swift` (`Search.recentIconName`) | SF Symbol name |
| Recent searches kept: 5 | `Constants.swift` (`Search.recentLimit`) | Maximum saved searches |

## 7. iOS search and enquiry behaviour (code)

| Value | Where | Meaning |
| --- | --- | --- |
| Search minimum 2 characters | `Constants.swift` (`Search.minLength`) | Matches the backend |
| Search maximum 100 characters | `Constants.swift` (`Search.maxLength`) | Matches the backend |
| Debounce 300 ms | `Constants.swift` (`Search.debounce`) | Quiet time before a request |
| Page size 20 | `Constants.swift` (`Search.pageSize`) | Matches the backend default |
| VoiceOver announcement at most once per 1 s | `Constants.swift` (`Search.announcementThrottle`) | Throttle |
| Enquiry name max 100, message max 1000 | `ios/.../Domain/Enquiry.swift` (`EnquiryLimits`) | Matches the backend |
| Message counter shown from 900 characters | `Enquiry.swift` (`EnquiryLimits.counterThreshold`) | Counter threshold |
| Phone 10 digits | `ios/.../Domain/Validators.swift` (`MobileValidator.digitCount`) | Matches the backend |
| Email pattern | `Validators.swift` (`EmailValidator.pattern`) | Matches the backend |
| Product description collapses after 160 characters, to 4 lines | `Constants.swift` (`ProductPage.descriptionCollapseLength`, `descriptionCollapsedLines`) | Show more |
| Gallery zoom up to 4× | `Constants.swift` (`ProductPage.maxZoom`) | Pinch zoom limit |
| Rating shown with a fixed number of decimal places | `Constants.swift` (`Home.ratingDecimalPlaces`) | Rating text |

## 8. iOS layout and visual values (code)

These are design values in `ios/.../Core/Constants.swift`. They can move to the design system later.

| Group | Examples |
| --- | --- |
| Home grid | spacing 16, minimum column width 160, featured card width 185, category minimum width 150 |
| Card and tile sizes | card corner radius 12, card image height 160, detail image height 280, category tile height 64, category badge 36 |
| Corner radii | category tiles 14, enquiry cards 14 |
| Enquiry layout | minimum touch target 44, message minimum height 120, icon size 22, divider inset 48, success icon 64 |
| Featured arrows | size 36, shadow opacity 0.15, fade 0.2 s |
| Colours | category accent `#334155` (`CategoryPalette.swift`), neutral grey, and the system colours used elsewhere |
| Touch target | 44 pt (`Layout.minTouchTarget`, `Search.touchTarget`) |

## 9. Business and data assumptions

| Value | Where | Meaning | Note |
| --- | --- | --- | --- |
| Currency `USD` | `Constants.swift` (`Currency.code`) | Currency for all prices | Fake Store prices are in USD |
| Featured list `backend/data/featured.json` | `backend/data/` | The admin's chosen products | No admin UI. Edit the file |
| Categories come from Fake Store | `productService.ts` | Category list | The app shows whatever the backend sends |
| Marketing consent unticked by default | `ios/.../Domain/Enquiry.swift` | Consent default | Matches the brief |
| Enquiry emails are logged, not sent | `backend/src/infra/logEmailSender.ts` | Email adapter | Replace with a real `EmailSender` |

## 10. Placeholders to replace before production

1. `https://api.example.com` and `https://staging.api.example.com` (`AppEnvironment.swift`).
2. `https://example.com/privacy` (`Constants.swift`, `Enquiry.privacyPolicyURL`).
3. `sales@example.com` (`config.ts`). Set `SALES_INBOX` for real use.
4. `http://localhost:3000` in the backend startup log (`server.ts`). It does not follow `PORT`.

## 11. Suggested first items to make configurable

Ordered by how often they would change:

1. Backend and app base URLs, including the production and staging hosts.
2. The Fake Store base URL and the upstream timeout (already in config).
3. Search and enquiry limits, so backend and app share one source (today they are duplicated in `search.ts`, `enquiry.ts`, `Constants.swift` and `Enquiry.swift`).
4. The privacy policy URL and the sales inbox.
5. Visual constants, once a design system exists.
