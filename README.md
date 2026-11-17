# CatalogueKit

A product catalogue proof of concept: an iOS app (SwiftUI) that browses and searches products, and sends enquiries about them. It talks only to a local Node.js backend, which holds the product data source behind an interface.

Decisions and assumptions are in [DECISIONS.md](DECISIONS.md). How AI tools were used is in [AI_USAGE.md](AI_USAGE.md). Agent instructions for this repo are in [CLAUDE.md](CLAUDE.md).

## Choices

- **Client: iOS (Swift, SwiftUI).** The challenge lists iOS as an option. Native SwiftUI gives the Simulator run that the brief asks for, and the architecture in `CLAUDE.md` (Domain, Data, Presentation) keeps the UI separate from the data source.
- **Backend: Node.js with TypeScript and Express 5.** It is the preferred option in the brief. One language across the backend and tests keeps the product-source adapter and the tests simple.
- **Data:** Fake Store API, through the backend only. The app never calls it directly.

## Requirements

- macOS with Xcode 16 or later, and an iOS Simulator (the project uses iPhone 17 Pro).
- Node.js 20 or later (tested on Node 22).
- No paid services or accounts.

## Run the backend

```bash
cd backend
cp .env.example .env
npm install
npm run dev
```

The backend listens on `http://localhost:3000`. Check it with `curl http://localhost:3000/health`.

Configuration is in `backend/.env.example`. The defaults are enough to run. The enquiry email is written to the console, so no mail account is needed. `SALES_INBOX` sets the recipient shown in that log line.

## Run the iOS app

1. Start the backend (above).
2. Open `ios/CatalogueKit/CatalogueKit.xcodeproj` in Xcode.
3. Pick the `CatalogueKit` scheme and an iPhone Simulator, then press Run.

Debug builds use `http://localhost:3000` (the `develop` environment). To point at another backend, set the `API_BASE_URL` environment variable in the scheme.

## Tests

Backend (typecheck and 61 tests):

```bash
cd backend
npm run typecheck
npm test
```

iOS unit tests (106 tests, on the Simulator):

```bash
cd ios/CatalogueKit
xcodebuild test -project CatalogueKit.xcodeproj -scheme CatalogueKit \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:CatalogueKitTests
```

## Project layout

```
backend/
  src/domain/       product, search and enquiry rules (no framework code)
  src/services/     ProductService (cache, ranking, search), EnquiryService
  src/data/         FakeStoreClient: the only code that knows the Fake Store API
  src/http/         Express routes and error handling
  src/infra/        LogEmailSender (the email adapter)
  test/             Vitest and supertest tests
ios/CatalogueKit/CatalogueKit/
  Domain/           entities, use cases, repository protocols, validators
  Data/             HTTP client, DTOs, repositories, image and disk caches
  Presentation/     SwiftUI views and view models (Home, Category, Search, Product, Enquiry)
  App/              AppContainer, the composition root
  Core/             constants, localized strings, environment
```

## API

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/health` | Liveness check |
| GET | `/products/featured` | The admin's featured list, in order (`FEATURED_COUNT` caps it) |
| GET | `/products/categories` | Every category, in backend order |
| GET | `/products/categories/:name` | Top rated products in a category, then the rest |
| GET | `/products/search?q=&category=&offset=&limit=` | Search, best rated first. Two to 100 characters. Pages of 20 |
| GET | `/products/:id` | One product, or 404 |
| POST | `/enquiries` | Enquiry for a product. Returns 201, or 400 with field errors, 404 for an unknown product, 413 over 16 KB |

## Known limits

- The enquiry email is only logged. A real email provider is a new adapter behind `EmailSender`.
- The privacy policy link is a placeholder.
- The app was checked in portrait and dark mode on the Simulator. Landscape, VoiceOver and large text sizes need a check on a device.
- The product page does not show a discount, a "Low stock" status, specifications beyond category, product ID and rating, or a share button. Fake Store has no data for these. See DECISIONS.md, section 4.
